terraform {
  #Specify to use AWS S3 bucket to store Terraform state files
  backend "s3" {
    bucket  = "sctp-ce3-tfstate-bucket-1"  #Specify the name of S3 bucket where Terraform will store its state file
    key     = "environments/dev/deploy.tfstate" #Defines the key (path) within the S3 bucket where Terraform will store the state file for this specific environment
    region  = "us-east-1" #Specifies the AWS region where the S3 bucket is located.
  }
}