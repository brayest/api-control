terraform {
  backend "s3" {}
}

#  ########### Providers ###########

provider "aws" {
  region = var.application_account_region

  assume_role {
    role_arn     = var.application_account_role_arn
    session_name = "terraform"
    external_id  = var.application_account_external_id
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "lambda_edge"

  assume_role {
    role_arn     = var.application_account_role_arn
    session_name = "terraform"
    external_id  = var.application_account_external_id
  }
}

#  ############ Infrastructure ############

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "common_tags" {
  source      = "../modules/tags"
  stack       = "oneconnect"
  customer    = var.customer_name
  environment = var.environment
}

# Dynamo DB
module "dynamodb_table" {

  providers = {
    aws = aws.lambda_edge
  }

  source = "../modules/dynamodb"

  name      = module.common_tags.id
  hash_key  = "CUSTOMER_ID"
  range_key = "NAME"

  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attributes = [
    {
      name = "CUSTOMER_ID"
      type = "S"
    },
    {
      name = "NAME"
      type = "S"
    }
  ]

  server_side_encryption_enabled = true

  tags = module.common_tags.tags
}

# Lambda Function

resource "aws_iam_policy" "lambda_role_policy" {
  name        = "${module.common_tags.id}-controller"
  path        = "/"
  description = "Dynamo dynamo_controller lambda policy"
  policy = templatefile("./files/lambda-dynamo-policy.json", {
    resource_arn = module.dynamodb_table.this_dynamodb_table_arn
  })
}

module "dynamo_controller" {

  providers = {
    aws = aws.lambda_edge
  }

  source = "../modules/lambda_aws"

  function_name = "dynamo-${module.common_tags.id}"
  description   = "Lambda function to read and write to a dynamo table"
  handler       = "dynamo.lambda_handler"
  runtime       = "python3.8"

  source_path   = "./functions/dynamo.py"
  attach_policy = true
  policy        = aws_iam_policy.lambda_role_policy.arn

  publish = true

  environment_variables = {
    DYNAMO_TABLE = module.dynamodb_table.this_dynamodb_table_id
  }

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service = "apigateway"
      arn     = module.api_gateway.this_apigatewayv2_api_execution_arn
    }
  }

  tags = module.common_tags.tags
}

## Control API
resource "random_pet" "this" {
  length = 2
}

resource "aws_cloudwatch_log_group" "logs" {
  provider = aws.lambda_edge

  name = random_pet.this.id
}

module "api_gateway" {

  providers = {
    aws = aws.lambda_edge
  }

  source = "../modules/api_gateway"

  name          = module.common_tags.id
  description   = "One connect API GW"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  # Custom domain
  domain_name                 = "domain.com"
  domain_name_certificate_arn = var.certificate

  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.logs.arn
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  # Routes and integrations
  integrations = {
    "ANY /put" = {
      lambda_arn             = module.dynamo_controller.this_lambda_function_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }

    "ANY /get" = {
      lambda_arn             = module.dynamo_controller.this_lambda_function_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }

    "$default" = {
      lambda_arn = module.dynamo_controller.this_lambda_function_arn
    }
  }

  tags = module.common_tags.tags
}

## CloudFront Config
module "cloudfront_edge" {

  providers = {
    aws = aws.lambda_edge
  }

  source = "../modules/lambda_aws"

  lambda_at_edge = true

  function_name = "cloudfront-${module.common_tags.id}"
  description   = "Lambda function for Lambda@Edge"
  handler       = "cloudfront.lambda_handler"
  runtime       = "python3.8"

  source_path   = "./functions/cloudfront.py"
  attach_policy = true
  policy        = aws_iam_policy.lambda_role_policy.arn

  publish = true

  tags = module.common_tags.tags
}

# CloudFront
resource "aws_s3_bucket" "cloudfront_log_bucket" {
  bucket = "cloudfront-logs-${module.common_tags.id}"
  acl    = "private"
  tags = module.common_tags.tags
}

resource "aws_s3_bucket_policy" "cloudfront_log_bucket_policy" {
  bucket = aws_s3_bucket.cloudfront_log_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "CloudFront",
  "Statement": [
    {
      "Sid": "Auth",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.cloudfront_log_bucket.id}/*"
    }
  ]
}
POLICY
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "cloudfront-${module.common_tags.id}"
}

resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  origin {
    domain_name = "domain.com"
    origin_id   = "custom"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "match-viewer"
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      origin_keepalive_timeout = 60
      origin_read_timeout      = 60
    }
  }  

  logging_config {
    bucket = aws_s3_bucket.cloudfront_log_bucket.bucket_domain_name
    prefix = "cloudfront"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "cloudfront-${module.common_tags.id}"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "custom"

    forwarded_values {
      query_string = true
      headers      = ["Origin", "client", "fiToken", "appToken"]
      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = module.cloudfront_edge.this_lambda_function_qualified_arn
      include_body = true
    }    

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 86400
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = module.common_tags.tags

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}