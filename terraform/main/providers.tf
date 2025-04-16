terraform {
  
  # Optional: Configure backend for state storage
  backend "s3" {
    bucket = "terraform-states123456"
    key    = "blog/terraform.tfstate"
    use_lockfile = true
    kms_key_id = "arn:aws:kms:us-east-2:148761668913:key/687ac8fc-ec91-490a-92a4-07de2937366d"
    encrypt        = true
    region = "us-east-2"
    profile = "account1"
  }
}

provider "aws" {
  profile = "account2"
  region = var.aws_region
}