# Secrets Encrypted With SOPS
locals {
  # Decrypt SOPS secrets at runtime
  secrets = yamldecode(sops_decrypt_file("${get_parent_terragrunt_dir()}/secrets.enc.yaml"))

  # AWS
  aws_access_key = local.secrets.aws.access_key
  aws_secret_key = local.secrets.aws.secret_key

  # Cloudflare
  cloudflare_api_token = local.secrets.cloudflare.api_token

  # Proxmox
  pm_api_url          = local.secrets.proxmox.api_url
  pm_api_token_id     = local.secrets.proxmox.api_token_id
  pm_api_token_secret = local.secrets.proxmox.api_token_secret

  # Talos
  wireguard_private_key = local.secrets.talos.wireguard_private_key

}

# Secrets flow to the root module as input variables (TF_VAR_*), never
# rendered into generated files on disk.
inputs = {
  aws_access_key        = local.aws_access_key
  aws_secret_key        = local.aws_secret_key
  cloudflare_api_token  = local.cloudflare_api_token
  pm_api_url            = local.pm_api_url
  pm_api_token_id       = local.pm_api_token_id
  pm_api_token_secret   = local.pm_api_token_secret
  wireguard_private_key = local.wireguard_private_key
}

# AWS Lightsail S3 Backend
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }

  config = {
    bucket  = "hosted-fail-tf-state"
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true

    # S3-native state locking (Terraform >= 1.10)
    use_lockfile = true

    endpoints = {
      s3 = "https://hosted-fail-tf-state.s3.us-east-1.amazonaws.com"
    }

    use_path_style              = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
  }
}

# Generate Providers
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
    terraform {
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 6.0"
        }
        cloudflare = {
          source  = "cloudflare/cloudflare"
          version = "~> 5.10"
        }
        proxmox = {
          source  = "telmate/proxmox"
          version = "~> 3.0"
        }
        talos = {
          source  = "siderolabs/talos"
          version = "~> 0.9"
        }
      }
    }

    variable "aws_access_key" {
      description = "AWS access key for the Lightsail S3 backend account"
      type        = string
      sensitive   = true
    }

    variable "aws_secret_key" {
      description = "AWS secret key for the Lightsail S3 backend account"
      type        = string
      sensitive   = true
    }

    variable "cloudflare_api_token" {
      description = "Cloudflare API token"
      type        = string
      sensitive   = true
    }

    variable "pm_api_url" {
      description = "Proxmox API URL"
      type        = string
    }

    variable "pm_api_token_id" {
      description = "Proxmox API token ID"
      type        = string
      sensitive   = true
    }

    variable "pm_api_token_secret" {
      description = "Proxmox API token secret"
      type        = string
      sensitive   = true
    }

    provider "aws" {
      region                      = "us-east-1"
      access_key                  = var.aws_access_key
      secret_key                  = var.aws_secret_key
      skip_credentials_validation = true
      skip_requesting_account_id  = true
      s3_use_path_style           = true
    }
    provider "cloudflare" {
      api_token = var.cloudflare_api_token
    }
    provider "proxmox" {
      pm_api_url          = var.pm_api_url
      pm_api_token_id     = var.pm_api_token_id
      pm_api_token_secret = var.pm_api_token_secret
      pm_tls_insecure     = false
    }
    EOF
}
