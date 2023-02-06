terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }

  }
}

resource "random_string" "cluster_id" {
    length = 5
    special = false
    upper = false
}