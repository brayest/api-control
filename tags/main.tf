locals {
  id_context = {
    name        = var.name
    stack       = var.stack
    customer    = var.customer
    environment = var.environment
  }

  tag_name = lower(lookup(var.tags, "Name", "")) # check to see if we already have a name tag set.
  # run loop for label order and set in value.
  id_labels = [for l in var.order : local.id_context[l] if length(local.id_context[l]) > 0]
  id_full   = lower(join(var.delimiter, local.id_labels))
  id        = local.tag_name != "" ? "${local.tag_name}${var.delimiter}${local.id_full}" : local.id_full

  local_tags = {
    # Name                = upper(local.id)
    Customer            = var.customer
    Stack               = var.stack
    Environment         = var.environment
    terraform_workspace = terraform.workspace
  }

  generated_tags = { for l in keys(local.local_tags) : title(l) => local.local_tags[l] if length(local.local_tags[l]) > 0 }

  tags = merge(
    var.tags,
    local.generated_tags
  )

  tags_as_list_of_maps = flatten([
    for key in keys(local.tags) : merge(
      {
        key   = key
        value = local.tags[key]
    })
  ])

}
