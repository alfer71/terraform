# Specify the Terraform version and provider
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "primary"  # Assign an alias to this provider configuration
  region = "us-east-1"  # Change to your preferred AWS region
}

# Create a private ECR repository
resource "aws_ecr_repository" "my_repository" {
  provider             = aws.primary  # Refer to the aliased provider here
  name                 = "my-docker-repo"  # Change to your preferred repository name
  image_tag_mutability = "MUTABLE"         # Set to "IMMUTABLE" if you want to prevent image tag overwriting
  image_scanning_configuration {
    scan_on_push = true  # Enable image scanning on push
  }

  encryption_configuration {
    encryption_type = "AES256"  # Default encryption; set to "KMS" for using a KMS key
  }
}

# Create a lifecycle policy for the ECR repository
resource "aws_ecr_lifecycle_policy" "my_repository_policy" {
  repository = aws_ecr_repository.my_repository.name
  policy = <<POLICY
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Expire untagged images older than 30 days",
        "selection": {
          "tagStatus": "untagged",
          "countType": "sinceImagePushed",
          "countUnit": "days",
          "countNumber": 30
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  POLICY
}

# Output the repository URI
output "ecr_repository_uri" {
  value       = aws_ecr_repository.my_repository.repository_url
  description = "The URL of the ECR repository"
}
