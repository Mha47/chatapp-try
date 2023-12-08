# Configure the Terraform backend to use Amazon S3 to store the state file.
terraform {
  backend "s3" {
    bucket  = "sctp-ce3-tfstate-bucket-1"
    key     = "environments/modules/ecr/ecr.tfstate"
    region  = "us-east-1"
  }
}