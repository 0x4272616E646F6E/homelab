variable "region" {
  description = "AWS region for the Lightsail bucket"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "hosted-fail-tf-state"
}

variable "aws_access_key" {
  description = "AWS access key for Lightsail"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key for Lightsail"
  type        = string
  sensitive   = true
}
