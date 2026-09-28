# The file system behind the efs-sc StorageClass, which the demo app's
# /orders/efs endpoint stores orders on

resource "aws_efs_file_system" "demo" {
  creation_token = "${local.cluster_name}-demo"
  encrypted      = true

  tags = { Name = "${local.cluster_name}-demo" }
}

resource "aws_security_group" "efs" {
  name_prefix = "${local.cluster_name}-efs-"
  description = "NFS from the cluster VPC to the demo EFS file system"
  vpc_id      = module.platform.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "efs_nfs" {
  security_group_id = aws_security_group.efs.id
  cidr_ipv4         = local.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049
}

# One per private subnet (one per AZ), so every node can mount it
resource "aws_efs_mount_target" "demo" {
  count = length(module.platform.private_subnet_ids)

  file_system_id  = aws_efs_file_system.demo.id
  subnet_id       = module.platform.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "kubernetes_storage_class_v1" "efs" {
  metadata {
    name = "efs-sc"
  }

  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap" # an access point per PersistentVolumeClaim
    fileSystemId     = aws_efs_file_system.demo.id
    directoryPerms   = "700"
  }

  depends_on = [aws_efs_mount_target.demo]
}
