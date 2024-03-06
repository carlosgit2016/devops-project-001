locals {
  project_name = "devops-project-001"
}


terraform {
  backend "s3" {
    key    = "infrastructure/aws/terraform.tfstate"
    bucket = "devops-project-001-terraform-state"
    acl    = "private"
    region = "us-east-1"
  }

}

provider "aws" {
  default_tags {
    tags = {
      project     = "devops-project-001"
      environment = "lowers"
    }
  }
}