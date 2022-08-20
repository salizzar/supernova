terraform {
  backend "s3" {
    bucket  = "marcelopinheiro-co-tfstate"
    key     = "websites/marcelopinheiro.co/terraform.tfstate"
    encrypt = "true"
    region  = "us-east-1"
    profile = "marcelopinheiro-co-shared"
  }
}

