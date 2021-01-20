output "id" {
  value       = local.id
  description = "Name id to be applied to resources"
}

output "environment" {
  value       = var.environment
  description = "Environment"
}

output "tags" {
  value       = local.tags
  description = "Tags as a map (includes a `Name` tag)"
}

output "tags_as_list_of_maps" {
  description = "Tags as a list of maps (includes a `Name` tag)"
  value       = local.tags_as_list_of_maps
}
