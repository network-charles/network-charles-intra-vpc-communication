terraform {
  backend "local" {
    path = "relative/path/to/terraform.tfstate" #Add your file path
  }
}


  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
