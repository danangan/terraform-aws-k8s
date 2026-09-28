# The operator allocates ENIs and pod IPs through the EC2 API:
# https://docs.cilium.io/en/stable/network/concepts/ipam/eni/#required-privileges
data "aws_iam_policy_document" "operator" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AssignPrivateIpAddresses",
      "ec2:AttachNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:CreateTags",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:UnassignPrivateIpAddresses",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "operator_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "operator" {
  name               = "${var.cluster_name}-cilium-operator"
  assume_role_policy = data.aws_iam_policy_document.operator_assume_role.json
}

resource "aws_iam_role_policy" "operator" {
  name   = "cilium-eni"
  role   = aws_iam_role.operator.name
  policy = data.aws_iam_policy_document.operator.json
}

resource "aws_eks_pod_identity_association" "operator" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "cilium-operator"
  role_arn        = aws_iam_role.operator.arn
}

resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = var.chart_version
  namespace  = "kube-system"

  # Installed before the node groups exist (nodes can't become Ready without a
  # CNI), so there's nothing to wait for yet
  wait = false

  values = [yamlencode({
    eni                  = { enabled = true, subnetIDsFilter = var.subnet_ids }
    ipam                 = { mode = "eni" }
    routingMode          = "native"
    kubeProxyReplacement = true
    k8sServiceHost = trimprefix(var.cluster_endpoint, "https://")
    k8sServicePort = 443

    encryption = { enabled = true, type = "wireguard" }
  })]

  depends_on = [aws_iam_role_policy.operator, aws_eks_pod_identity_association.operator]
}

resource "aws_vpc_security_group_ingress_rule" "wireguard" {
  description                  = "Cilium WireGuard tunnels between nodes"
  security_group_id            = var.node_security_group_id
  referenced_security_group_id = var.node_security_group_id
  ip_protocol                  = "udp"
  from_port                    = 51871
  to_port                      = 51871
}
