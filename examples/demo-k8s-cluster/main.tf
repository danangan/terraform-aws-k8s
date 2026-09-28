terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.2"
    }
  }
}

locals {
  region       = "us-east-1"
  cluster_name = "platform-cluster"
  vpc_cidr     = "10.0.0.0/16"
}

provider "aws" {
  region = local.region
}

provider "helm" {
  kubernetes = {
    host                   = module.platform.cluster_endpoint
    cluster_ca_certificate = base64decode(module.platform.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", local.region]
    }
  }
}

# For the efs-sc StorageClass in efs.tf
provider "kubernetes" {
  host                   = module.platform.cluster_endpoint
  cluster_ca_certificate = base64decode(module.platform.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", local.region]
  }
}

module "platform" {
  source = "../.."

  aws_region   = local.region
  cluster_name = local.cluster_name

  vpc_cidr                = local.vpc_cidr
  availability_zone_count = 2

  kubernetes_version = "1.33"

  cpu_instance_type           = "t4g.small"
  cpu_node_group_min_size     = 0
  cpu_node_group_max_size     = 2
  cpu_node_group_desired_size = 2

  gpu_instance_type           = "g4dn.xlarge"
  gpu_node_group_min_size     = 0
  gpu_node_group_max_size     = 1
  gpu_node_group_desired_size = 0

  enable_efs_csi_driver = true
  enable_cilium         = true
}

output ecr_repository_url {
  value       = module.platform.ecr_repository_url
}


output "cluster_name" {
  value = module.platform.cluster_name
}
