output "app_url" {
  description = "Public URL of the deployed application."
  value       = "http://${aws_instance.app.public_ip}"
}

output "ec2_instance_id" {
  description = "Instance ID to configure as the EC2_INSTANCE_ID GitHub variable."
  value       = aws_instance.app.id
}

output "artifact_bucket" {
  description = "S3 bucket to configure as the ARTIFACT_BUCKET GitHub variable."
  value       = aws_s3_bucket.artifacts.bucket
}

output "github_actions_role_arn" {
  description = "Role ARN to configure as the AWS_ROLE_ARN GitHub variable."
  value       = aws_iam_role.github_actions.arn
}
