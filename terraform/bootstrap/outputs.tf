output "bucket_name" {
  description = "Name of the created S3 state bucket"
  value       = aws_s3_bucket.tf_state.id
}

output "bucket_arn" {
  description = "ARN of the created S3 state bucket"
  value       = aws_s3_bucket.tf_state.arn
}
