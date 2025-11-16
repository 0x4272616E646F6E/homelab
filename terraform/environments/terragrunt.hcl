include "root" {
  path = find_in_parent_folders("root.hcl")
}

source = "../modules"

inputs = {
  environment = "terragrunt"
}
