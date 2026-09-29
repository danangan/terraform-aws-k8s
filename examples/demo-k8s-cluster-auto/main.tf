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
  cluster_name = "demo-cluster-auto"
  vpc_cidr     = "10.0.0.0/16"
}

provider "aws" {
  region = local.region
}

# The module installs its Auto Mode config (IngressClass, StorageClass, GPU
# node pool) through Helm
provider "helm" {
  kubernetes = {
    host                   = module.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", local.region]
    }
  }
}

# For the efs-sc StorageClass in efs.tf
provider "kubernetes" {
  host                   = module.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", local.region]
  }
}

module "cluster" {
  # The module at the repo root, so local changes are picked up. Outside this
  # repo, use the registry instead: source = "danangan/k8s/aws"
  source = "../.."

  aws_region   = local.region
  cluster_name = local.cluster_name

  vpc_cidr                = local.vpc_cidr
  availability_zone_count = 2

  kubernetes_version = "1.33"

  # EKS launches and manages the nodes, so there are no cpu_*/gpu_* node group
  # settings here
  enable_auto_mode = true

  enable_efs_csi_driver = true
}

output "ecr_repository_url" {
  value = module.cluster.ecr_repository_url
}

output "cluster_name" {
  value = module.cluster.cluster_name
}
