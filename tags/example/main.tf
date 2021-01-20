module "common" {
  source      = "../"
  customer    = "client"
  environment = "dev"
}

module "dmz_tags" {
  source = "../"
  name   = "dmz"
  tags   = module.common.tags
}

output "common_tags" {
  value = module.common
}

output "module_tags" {
  value = module.dmz_tags
}
