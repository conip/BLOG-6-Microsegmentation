terraform {
  cloud {
    organization = "CONIX"

    workspaces {
      name = "BLOG-6-Microsegmentation"
    }
  }
  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.99"
    }

    aviatrix = {
      source  = "aviatrixsystems/aviatrix"
      version = "2.22.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "~>3.0.0"
    }
  }
}

