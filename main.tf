locals {
  # Auto Mode manages networking itself
  enable_cilium = var.enable_cilium && !var.enable_auto_mode

  addons = merge(
    {
      coredns                = {}
      eks-pod-identity-agent = { before_compute = true }
    },
    # Cilium replaces both
    local.enable_cilium ? {} : {
      kube-proxy = {}
      vpc-cni    = { before_compute = true }
    },
    var.extra_addons,
  )
}

module "network" {
  source = "./modules/network"

  cluster_name                = var.cluster_name
  vpc_cidr                    = var.vpc_cidr
  availability_zone_count     = var.availability_zone_count
  enable_multi_az_nat_gateway = var.enable_multi_az_nat_gateway
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  enable_auto_mode   = var.enable_auto_mode
  addons             = local.addons

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnets

  cpu_instance_type           = var.cpu_instance_type
  cpu_node_group_min_size     = var.cpu_node_group_min_size
  cpu_node_group_max_size     = var.cpu_node_group_max_size
  cpu_node_group_desired_size = var.cpu_node_group_desired_size

  gpu_instance_type           = var.gpu_instance_type
  gpu_node_group_min_size     = var.gpu_node_group_min_size
  gpu_node_group_max_size     = var.gpu_node_group_max_size
  gpu_node_group_desired_size = var.gpu_node_group_desired_size
  gpu_node_taints             = var.gpu_node_taints

  # This is a hack so that the node group creation would wait for the cillium installation
  # Basically creating a dependency between the node group resource and label resource from cillium module
  node_labels = local.enable_cilium ? module.cilium[0].node_labels : {}
}

module "cilium" {
  source = "./modules/cilium"

  count = local.enable_cilium ? 1 : 0

  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  subnet_ids       = module.network.private_subnets

  node_security_group_id = module.eks.node_security_group_id
}

module "storage" {
  source = "./modules/storage"

  # Auto Mode has its own built-in EBS support
  count = var.enable_auto_mode ? 0 : 1

  cluster_name       = module.eks.cluster_name
  kubernetes_version = var.kubernetes_version

  depends_on = [module.eks]
}

module "efs" {
  source = "./modules/efs"

  count = var.enable_efs_csi_driver ? 1 : 0

  cluster_name       = module.eks.cluster_name
  kubernetes_version = var.kubernetes_version

  depends_on = [module.eks]
}

module "ecr" {
  source = "./modules/ecr"

  repository_name = "${var.cluster_name}-repo"
}

module "alb_controller" {
  source = "./modules/alb-controller"

  # Auto Mode has its own built-in ALB/NLB controller
  count = var.enable_auto_mode ? 0 : 1

  aws_region   = var.aws_region
  cluster_name = module.eks.cluster_name
  vpc_id       = module.network.vpc_id

  depends_on = [module.eks]
}

module "auto_mode" {
  source = "./modules/auto-mode"

  count = var.enable_auto_mode ? 1 : 0

  # The GPU node group's settings, for the GPU node pool
  gpu_instance_type = var.gpu_instance_type
  gpu_limit         = var.gpu_node_group_max_size # one GPU per node on the default g4dn.xlarge
  gpu_node_taints   = var.gpu_node_taints

  # Auto Mode's NodePool and IngressClassParams types only exist once the cluster does
  depends_on = [module.eks]
}
