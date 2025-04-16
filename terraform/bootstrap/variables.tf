variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-2"
}

variable "terraform_state_access_role_arn" {
  description = "The ARN of the TerraformCrossAccountRole in Account A"
  type        = string
}