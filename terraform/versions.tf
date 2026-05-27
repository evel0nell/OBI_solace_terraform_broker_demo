terraform {
  required_version = ">= 1.5.0"

  required_providers {
    solacebroker = {
      source  = "solaceproducts/solacebroker"
      version = "~> 1.0"
    }
  }
}
