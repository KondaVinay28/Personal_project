variable "aws_region" {
  description = "AWS region for the project resources."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for the application."
  type        = string
  default     = "t3.micro"
}

variable "github_repository" {
  description = "GitHub repository allowed to deploy, in owner/repository format."
  type        = string
  default = "KondaVinay28/Personal_project"

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "Set github_repository to the GitHub owner/repository name."
  }
}
