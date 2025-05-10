terraform {
  backend "s3" {
    bucket = "proyecto-intranet-tfstate"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
