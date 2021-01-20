# Card App Service

This stack contains the infrastructure for Card App. The Terraform module creates the following resources:
- DMZ tier with an NLB/ALB setup.
- Application tier with an internal NLB/ALB setup and EC2 as the application layer.
- Database tier in a separate account.
- VPC peering connections to the multi-tenant Ondot accounts

## DMZ

### Network

![dmz-network](../images/dmz-network.png)

The DMZ network is composed of a VPC with public and private subnets across multiple availability zones. Each subnet layer (public and private) has it's own ACL and Route table. The public subnets have routes to the Internet gateway while the private subnets don't have internet access at all.

### Resources

![dmz](../images/dmz.png)

The DMZ has an NLB/ALB setup that works as a public entrypoint for the application tier. The NLB is deployed on the public subnets while the ALB is deployed as internal in the private subnets. A lambda function updates the NLB target groups with the ALB IPs (as the target groups don't allow domain names as targets) to forward the traffic from the NLB to the ALB. AWS WAF rules are associated with the ALB.

## Application

### Network

![application-network](../images/application-network.png)

The application network contains a VPC with NAT gateways in each AZ for HA and public, private and intra subnet layers:
- Public subnets: They use a single route table with routes to the Internet gateway
- Private subnets: Each private subnet layer has a route table per availability zone for HA, in case that any of the AZs is down the remaining AZs still have access to the Internet by having it's own routes and NAT gateaway.
- Intra subnets: Each layer has one route table without access to the Internet.

Each subnet Layer has it's own access control list with rules specific to it.

The following subnets are created as part of the CAS stack:
- public
- private
    - application
    - bastion
- intra
    - nlb
    - alb
    - efs
    - kms
    - api
    - redis
    - es

### Resources

![cas-application](../images/cas-application.png)

The application also has another NLB/ALB setup like the one in the DMZ tier, but in this case deploying both the NLB and ALB in private subnets as internal load balancers.

As part of the CAS application stack the following resources are created:
- EFS file system in the private subnets, allowing access only from the application subnet
- Bastion host with access to the application layer
- EC2 instances with custom scripts for the application
- VPC endpoints:
    - S3
    - Dynamo
    - KMS

The `general_peering` file, creates VPC peering connections to the shared accounts. All peering connections are handled by the `vpc_peering` module. The cross-account roles for each of the account has to be provided in the parameters in order to create and accept the peering connections.

## Database

![database](../images/database.png)

The database tier is deployed in a separate AWS account, so parameters with the Database cross-account role details are required. The database tier is parameterized to create a new VPC or using an existing one by using the `database_create_vpc` parameter.

The Database VPC only contains private subnets without Internet access.



<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.13.0 |
| aws | ~> 3.2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.2.0 |
| aws.database | ~> 3.2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| application\_account\_external\_id | External id of the application Role | `string` | `""` | no |
| application\_account\_region | Region where the resources should be deployed in the application account | `string` | `"us-west-2"` | no |
| application\_account\_role\_arn | ARN of a role in the application account to assume (with permissions to deploy resources) | `string` | `""` | no |
| apps\_vpc\_cidr | The CIDR block for the APPS VPC | `string` | `"10.61.0.0/24"` | no |
| apps\_vpc\_offset | Offset for the APPS subnets CIDR (newbits count) | `number` | `6` | no |
| azs\_count | Number of availability zones to use | `number` | `2` | no |
| bgp\_asn\_2 | The gateway's Border Gateway Protocol (BGP) Autonomous System Number (ASN). For VPN 2 | `string` | `"32944"` | no |
| certificate\_arn | ACM certificate ARN to attach to the load balancers | `string` | n/a | yes |
| communication\_manager\_account\_external\_id | Shared Services Assume Role External ID | `string` | `"46ade490-1193-7b95-0267-c66940dc6588"` | no |
| communication\_manager\_account\_region | Shared Services Region | `string` | `"us-west-2"` | no |
| communication\_manager\_account\_role\_arn | Shared Services VPC Assume Role ARN | `string` | `"arn:aws:iam::129473742006:role/ondot-cross-account-terraform-deployment"` | no |
| communication\_manager\_create\_peering | Create Peering connection | `bool` | `true` | no |
| communication\_manager\_routetable\_ids | Shared Services Route table IDs | `list` | <pre>[<br>  "rtb-ee513895"<br>]</pre> | no |
| communication\_manager\_vpc\_id | Shared Services VPC ID | `string` | `"vpc-331c904b"` | no |
| configurations\_bucket | Bucket where large configuration is stored (Optional) | `string` | `""` | no |
| customer\_gateway\_ip\_address\_1 | VPN customer gateway IP | `string` | `"12.1.2.4"` | no |
| customer\_gateway\_ip\_address\_2 | VPN customer gateway IP | `string` | `"12.1.2.4"` | no |
| customer\_name | Name of the customer. This will be used on resources tags | `string` | `"dev"` | no |
| data\_dog\_api\_key | Data Dog API Key (Optional) | `string` | `""` | no |
| database\_account\_external\_id | External id of the database Role | `string` | `""` | no |
| database\_account\_region | Region where the resources should be deployed in the database account | `string` | `"us-west-2"` | no |
| database\_account\_role\_arn | ARN of a role in the database account to assume (with permissions to deploy resources) | `string` | `""` | no |
| database\_azs\_count | Number of availability zones to use | `number` | `2` | no |
| database\_create\_vpc | Whether to create a new VPC or use an existing one in the database account | `bool` | `false` | no |
| database\_name | Database Name | `string` | `"ondot"` | no |
| database\_vpc\_cidr | The CIDR block for the database VPC | `string` | `"10.62.0.0/24"` | no |
| database\_vpc\_id | Id of the VPC to use in the database account. (used if create\_database\_vpc is set to false) | `string` | `""` | no |
| database\_vpc\_offset | Offset for the database VPC subnets CIDR (newbits count) | `number` | `2` | no |
| db\_allocated\_storage | Database allocated storage | `number` | `200` | no |
| db\_allowed\_security\_groups | Database allowed security groups | `list` | `[]` | no |
| db\_delete\_protection | Database delete protection | `bool` | `false` | no |
| db\_engine | Database Engine | `string` | `"oracle-se2"` | no |
| db\_engine\_version | Database engine version | `string` | `"12.1.0.2.v21"` | no |
| db\_instance\_class | Database instance class | `string` | `"db.m4.large"` | no |
| db\_license\_model | License Model | `string` | `"license-included"` | no |
| db\_master\_password | Database master password | `string` | `"f1ym6Wx0jKI$RpWn#RIb"` | no |
| db\_master\_user | Database master user | `string` | `"master"` | no |
| db\_parameter\_group\_family | Parameter group family | `string` | `"oracle-se-11.2"` | no |
| db\_port | Database port | `string` | `"3306"` | no |
| dmz\_vpc\_cidr | The CIDR block for the DMZ VPC | `string` | `"10.60.0.0/24"` | no |
| dmz\_vpc\_offset | Offset for the DMZ subnets CIDR (newbits count) | `number` | `2` | no |
| ec2\_image\_id | EC2 Image to use | `string` | `"ami-06f4a56c553a7e01e"` | no |
| ec2\_key\_name | EC2 Access Key Name | `string` | `"brayest-od-eng-us-east-2"` | no |
| efs\_mount\_point | EFS mount point | `string` | `"/mnt/efs"` | no |
| enable\_vpn | Enable VPN | `bool` | `true` | no |
| enable\_vpn\_2 | Enable second VPN with BGP configuration | `bool` | `true` | no |
| environment | Environment to tag the resources | `string` | `"dev"` | no |
| instance\_type | EC2 Instance type | `string` | `"t2.medium"` | no |
| primary\_destination\_cidr\_block | VPN primary destination CIDR for routes | `string` | `"10.20.0.0/16"` | no |
| shared\_services\_account\_external\_id | Shared Services Assume Role External ID | `string` | `"46ade490-1193-7b95-0267-c66940dc6588"` | no |
| shared\_services\_account\_region | Shared Services Region | `string` | `"us-west-2"` | no |
| shared\_services\_account\_role\_arn | Shared Services VPC Assume Role ARN | `string` | `"arn:aws:iam::092143237601:role/ondot-terraform-deployment-cross-account"` | no |
| shared\_services\_create\_peering | Create Peering connection | `bool` | `true` | no |
| shared\_services\_routetable\_ids | Shared Services Route table IDs | `list` | <pre>[<br>  "rtb-f9c0bc82"<br>]</pre> | no |
| shared\_services\_vpc\_id | Shared Services VPC ID | `string` | `"vpc-a2ec7eda"` | no |
| single\_nat\_gateway | Should be true if you want to provision a single shared NAT Gateway across all of your private networks | `bool` | `false` | no |
| spending\_insights\_account\_external\_id | Shared Services Assume Role External ID | `string` | `"46ade490-1193-7b95-0267-c66940dc6588"` | no |
| spending\_insights\_account\_region | Shared Services Region | `string` | `"us-west-2"` | no |
| spending\_insights\_account\_role\_arn | Shared Services VPC Assume Role ARN | `string` | `"arn:aws:iam::129473742006:role/ondot-cross-account-terraform-deployment"` | no |
| spending\_insights\_create\_peering | Create Peering connection | `bool` | `true` | no |
| spending\_insights\_routetable\_ids | Shared Services Route table IDs | `list` | <pre>[<br>  "rtb-ee513895"<br>]</pre> | no |
| spending\_insights\_vpc\_id | Shared Services VPC ID | `string` | `"vpc-331c904b"` | no |
| tdi\_account\_external\_id | Shared Services Assume Role External ID | `string` | `"46ade490-1193-7b95-0267-c66940dc6588"` | no |
| tdi\_account\_region | Shared Services Region | `string` | `"us-west-2"` | no |
| tdi\_account\_role\_arn | Shared Services VPC Assume Role ARN | `string` | `"arn:aws:iam::129473742006:role/ondot-cross-account-terraform-deployment"` | no |
| tdi\_create\_peering | Create Peering connection | `bool` | `true` | no |
| tdi\_routetable\_ids | Shared Services Route table IDs | `list` | <pre>[<br>  "rtb-ee513895"<br>]</pre> | no |
| tdi\_vpc\_id | Shared Services VPC ID | `string` | `"vpc-331c904b"` | no |

## Outputs

| Name | Description |
|------|-------------|
| apps\_alb\_arn | ARN of the Apps ALB. |
| apps\_alb\_dns\_name | DNS name of the Apps ALB. |
| apps\_alb\_route\_table\_ids | List of IDs of ALB route tables |
| apps\_alb\_security\_group\_id | Apps ALB security group ID. |
| apps\_alb\_subnet\_cidrs | List of CIDRs of the subnets |
| apps\_alb\_subnet\_ids | List of IDs of ALB subnets |
| apps\_api\_route\_table\_ids | List of IDs of API route tables |
| apps\_api\_subnet\_ids | List of IDs of API subnets |
| apps\_apigtw\_subnet\_cidrs | List of CIDRs of the subnets |
| apps\_application\_route\_table\_ids | List of IDs of application route tables |
| apps\_application\_subnet\_cidrs | List of CIDRs of the subnets |
| apps\_application\_subnet\_ids | List of IDs of application subnets |
| apps\_bastion\_route\_table\_ids | List of IDs of bastion route tables |
| apps\_bastion\_subnet\_cidrs | List of CIDRs of the subnets |
| apps\_bastion\_subnet\_ids | List of IDs of bastion subnets |
| apps\_efs\_route\_table\_ids | List of IDs of EFS route tables |
| apps\_efs\_subnet\_cidrs | List of CIDRs of the subnets |
| apps\_efs\_subnet\_ids | List of IDs of EFS subnets |
| apps\_kms\_route\_table\_ids | List of IDs of KMS route tables |
| apps\_kms\_subnet\_cidrs | List of CIDRs of the subnets |
| apps\_kms\_subnet\_ids | List of IDs of KMS subnets |
| apps\_nat\_public\_ips | List of public Elastic IPs created for AWS NAT Gateway |
| apps\_nlb\_arn | ARN of the Apps NLB. |
| apps\_nlb\_dns\_name | DNS name of the Apps NLB. |
| apps\_nlb\_route\_table\_ids | List of IDs of NLB route tables |
| apps\_nlb\_subnet\_cidrs | List of CIDRs of the subnets |
| apps\_nlb\_subnet\_ids | List of IDs of NLB subnets |
| apps\_public\_route\_table\_ids | List of IDs of public route tables |
| apps\_public\_subnet\_cidrs | List of CIDRs of the subnets |
| apps\_public\_subnet\_ids | List of IDs of public subnets |
| apps\_subnet\_cidrs | List of CIDRs of the subnets |
| apps\_vpc\_cidr\_block | The CIDR block of the VPC |
| apps\_vpc\_id | The ID of the VPC |
| customer\_gateway\_id | List of CIDRs of the subnets |
| customer\_gateway\_id\_2 | List of CIDRs of the subnets |
| database\_intra\_subnet\_cidrs | List of CIDRs of the subnets |
| database\_subnet\_cidrs | List of CIDRs of the subnets |
| dmz\_alb\_arn | ARN of the DMZ ALB. |
| dmz\_alb\_dns\_name | DNS name of the DMZ ALB. |
| dmz\_alb\_https\_listener\_arns | DMZ NLB/ALB Listner Rules ARN |
| dmz\_alb\_security\_group\_id | DMZ ALB security group ID. |
| dmz\_nlb\_arn | ARN of the DMZ NLB. |
| dmz\_nlb\_dns\_name | DNS name of the DMZ NLB. |
| dmz\_private\_route\_table\_ids | List of IDs of private route tables |
| dmz\_private\_subnet\_cidrs | List of CIDRs of the subnets |
| dmz\_private\_subnet\_ids | List of IDs of private subnets |
| dmz\_public\_route\_table\_ids | List of IDs of public route tables |
| dmz\_public\_subnet\_cidrs | List of CIDRs of the subnets |
| dmz\_public\_subnet\_ids | List of IDs of public subnets |
| dmz\_subnet\_cidrs | List of CIDRs of the subnets |
| dmz\_vpc\_cidr\_block | The CIDR block of the VPC |
| dmz\_vpc\_id | The ID of the VPC |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
