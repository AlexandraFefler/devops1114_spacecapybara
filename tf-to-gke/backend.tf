terraform {
  backend "s3" {
    bucket         = "spacecapy-bucket"
    key            = "terraform/state.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
