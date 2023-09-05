aws_profile = "marcelopinheiro-co-production"
aws_region  = "us-east-1"
domain      = "marcelopinheiro.co"

ibm_region = "us-east"

ibm_satellite_location = {
  location     = "us-east"
  zones        = ["us-east-1", "us-east-2", "us-east-3"]
  managed_from = "us-east"
}

ibm_iam_custom_role = {
  name         = "MarceloPinheiroCo"
  display_name = "MarceloPinheiroCo"
  description  = "Marcelo Pinheiro's website"
}

ibm_dns_zone = {
  description = "Marcelo Pinheiro's website"
}

