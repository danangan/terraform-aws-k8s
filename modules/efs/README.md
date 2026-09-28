# efs

Installs the [Amazon EFS CSI driver](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html) as an EKS add-on, following the AWS guide:

1. An IAM role for the driver's controller with the AWS managed `AmazonEFSCSIDriverPolicy`, granted through EKS Pod Identity (needs the `eks-pod-identity-agent` add-on, which the `eks` sub-module installs, or EKS Auto Mode, which has it built in).
2. The `aws-efs-csi-driver` EKS add-on, linked to that role.

It doesn't create a file system. Create one yourself (see the driver's [file system guide](https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/efs-create-filesystem.md)), then a StorageClass that uses it - see the root README's "EFS storage" section.

The add-on only becomes active once its controller pods are running, so apply this after the cluster's nodes exist - the root module does that with `depends_on = [module.eks]`.

## Inputs

| Name | Description | Default |
|---|---|---|
| `cluster_name` | Name of the EKS cluster to install the driver into | - |
| `kubernetes_version` | Kubernetes version of the cluster - used to look up the most recent add-on version | - |
| `addon_version` | Version of the `aws-efs-csi-driver` add-on. Defaults to the most recent one for `kubernetes_version` | `null` |

## Outputs

| Name | Description |
|---|---|
| `iam_role_arn` | ARN of the IAM role the driver's controller runs as |
