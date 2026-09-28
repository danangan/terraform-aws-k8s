output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster's Kubernetes API - needed by the caller to configure the kubernetes/helm providers"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA certificate of the EKS cluster - needed by the caller to configure the kubernetes/helm providers"
  value       = module.eks.cluster_certificate_authority_data
}

output "vpc_id" {
  description = "ID of the VPC the cluster runs in"
  value       = module.network.vpc_id
}

output "ecr_repository_url" {
  description = "URL of the app's ECR repository"
  value       = module.ecr.repository_url
}


output "private_subnet_ids" {
  description = "IDs of the private subnets the nodes run in"
  value       = module.network.private_subnets
}
