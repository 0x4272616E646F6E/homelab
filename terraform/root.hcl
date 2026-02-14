# Secrets Encrypted With SOPS
locals {
  # Decrypt SOPS secrets at runtime
  secrets = yamldecode(sops_decrypt_file("${get_terragrunt_dir()}/secrets.enc.yaml"))

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

# AWS Lightsail S3 Backend
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }

  config = {
    bucket   = "hosted-fail-tf-state"
    key      = "${path_relative_to_include()}/terraform.tfstate"
    region   = "us-east-1"
    endpoint = "https://hosted-fail-tf-state.s3.us-east-1.amazonaws.com"
    encrypt  = true

    s3_force_path_style         = true
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

    provider "aws" {
      region                      = "us-east-1"
      access_key                  = local.aws_access_key
      secret_key                  = local.aws_secret_key
      skip_credentials_validation = true
      skip_requesting_account_id  = true
      s3_force_path_style         = true
    }
    provider "cloudflare" {
      api_token = local.cloudflare_api_token
    }
    provider "proxmox" {
      pm_api_url          = local.pm_api_url
      pm_api_token_id     = local.pm_api_token_id
      pm_api_token_secret = local.pm_api_token_secret
      pm_tls_insecure     = true
    }
    EOF
}
