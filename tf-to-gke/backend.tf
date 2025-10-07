# backend mention - here's all the info on setting an s3 bucket in tf: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
terraform {
  backend "s3" {
    bucket         = "spacecapy-bucket"
    key            = "terraform/state.tfstate" #IRL, usually the key is indicating a separate .tfstate - like prod/state.tfstate and dev/state.tfstate
    region         = "us-east-1"
    encrypt        = true
  }
}
