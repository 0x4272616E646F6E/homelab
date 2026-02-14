include "root" {
  path = find_in_parent_folders("root.hcl")
}

source = "../modules"

inputs = {
  environment           = "terragrunt"
  wireguard_private_key = local.wireguard_private_key
}
