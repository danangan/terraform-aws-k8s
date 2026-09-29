# Kubernetes Terraform Module for AWS EKS

[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-232F3E?style=flat&logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat&logo=helm&logoColor=white)](https://helm.sh/)

This reusable Terraform module handles everything needed to stand up a Kubernetes cluster on AWS EKS:

- Complete network (VPC, public + private subnets across multiple AZs, Internet & NAT gateway)
- An EKS cluster with a CPU node group and a GPU node group
- An ECR repository
- The AWS Load Balancer Controller
- The EBS & EFS CSI driver for workload volume (EFS driver is optional)
- (Optional) [Cilium](#cilium) as the CNI instead of the VPC CNI and kube-proxy
- (Optional) [EKS Auto Mode](#eks-auto-mode) instead of the node groups and controller above, so EKS manages the nodes, ingress and storage itself

This module is published on the public Terraform Registry as [`danangan/k8s/aws`](https://registry.terraform.io/modules/danangan/k8s/aws/latest).

Point it at your AWS account and you'll have a cluster ready for your containerized workloads in minutes - no manual wiring required.

## Contents

- [Requirements](#requirements)
- [Example usage](#example-usage)
- [Deploying pods into the GPU nodes](#deploying-pods-into-the-gpu-nodes)
- [Add-ons](#add-ons)
- [EFS storage](#efs-storage)
- [Cilium](#cilium)
- [EKS Auto Mode](#eks-auto-mode)
- [Project structure](#project-structure)
- [Examples](#examples)

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.7.0 (pinned by the example; the module itself does not set `required_version`) |
| [aws provider](https://registry.terraform.io/providers/hashicorp/aws) | ~> 6.0 |
| [helm provider](https://registry.terraform.io/providers/hashicorp/helm) | ~> 3.0 |

The full list of inputs and outputs is generated on the [Terraform Registry page](https://registry.terraform.io/modules/danangan/k8s/aws/latest) from `variables.tf` and `outputs.tf`.

## Example usage

```hcl
provider "aws" {}

# This is an important setup to allow Terraform to install the Ingress Controller to the k8s cluster
provider "helm" {
  kubernetes = {
    host                   = module.platform.cluster_endpoint
    cluster_ca_certificate = base64decode(module.platform.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1"
      # In this example, we are using the `aws eks` command to authenticate to the k8s API.
      # For local use, authenticate to AWS first, e.g. via "aws login" or "aws sso login".
      # On a remote machine (e.g. your CI/CD workflow), authenticate via a static access key with "aws configure" instead.
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", local.region]
    }
  }
}

module "k8s_cluster" {
  source  = "danangan/k8s/aws"
  version = "~> 1.0"

  cluster_name = "my-k8s-cluster"
}
```

## Deploying pods into the GPU nodes

GPU nodes are expensive, so we should only use them sparingly and only deploy relevant workloads onto that node group. To do so, we can leverage Kubernetes' [taints and tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) feature. To deploy pods into the GPU nodes, you'd need to provision your workload with the following tolerations:
```
tolerations:
- key: "nvidia.com/gpu"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
```

You can override this configuration in the module with `gpu_node_taints` variable.

The GPU nodes' AMI doesn't include the NVIDIA device plugin, so the module installs it ([`modules/nvidia-device-plugin`](modules/nvidia-device-plugin/README.md)). Pods then request GPUs with `resources.limits: { nvidia.com/gpu: 1 }`.

With `enable_auto_mode = true` there's no GPU node group - the module creates a GPU `NodePool` from the same `gpu_*` settings (see [EKS Auto Mode](#eks-auto-mode)), which uses the same taint. GPU pods also need to request `nvidia.com/gpu` in their resources: that's what makes Auto Mode launch a GPU node for them.

## Add-ons

On the managed node groups (the default), the module installs these EKS add-ons:

- `coredns`
- `eks-pod-identity-agent`
- `kube-proxy` and `vpc-cni` (unless [Cilium](#cilium) replaces them)
- `aws-ebs-csi-driver`
- `aws-ebs-csi-driver` (optiona; see [EFS storage](#efs-storage))

Add more with `extra_addons`, keyed by add-on name. Each entry takes the same settings as an `addons` entry in [terraform-aws-modules/eks](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest). Example:

```hcl
module "platform" {
  source  = "danangan/k8s/aws"
  version = "~> 1.0"

  cluster_name = "my-other-project"

  extra_addons = {
    metrics-server      = {}
    snapshot-controller = {}
  }
}
```

To override the default add-ons setting you can do that by providing that addon setting via this property. 

## EFS storage

To enable EFS storage, set `enable_efs_csi_driver = true` to install the driver for it:

```hcl
module "platform" {
  source  = "danangan/k8s/aws"
  version = "~> 1.0"

  cluster_name = "my-other-project"

  enable_efs_csi_driver = true
}
```

To use EFS in your workload you need to:

- Provision the file system itself
- Provision the mount target
- Provision security group that allows NFS in/out from the VPC
- Create storage class (via kubectl or via terraform). Example via kubectl:

```
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-0123456789abcdef0 # your file system's ID
  directoryPerms: "700"
EOF
```

- Then you can use the EFS volume using PVC as follow:

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-data
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi # required by Kubernetes, but EFS doesn't enforce a size
```

See this article for more detailed guideline: (https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/efs-create-filesystem.md)

## Cilium

Set `enable_cilium = true` to replace the VPC CNI and kube-proxy with [Cilium](https://docs.cilium.io/en/stable/overview/intro/). With this option enabled:
- Pods still get VPC IPs ([ENI mode](https://docs.cilium.io/en/stable/network/concepts/ipam/eni/))
- Services are routed with eBPF instead of iptables
- pod traffic between nodes is encrypted with [WireGuard](https://docs.cilium.io/en/stable/security/network/encryption-wireguard/).

> Note: Not available with Auto Mode. Only for new clusters - switching one that runs the VPC CNI isn't handled. Details in [`modules/cilium`](modules/cilium/README.md).

## EKS Auto Mode

Set `enable_auto_mode = true` to run the cluster on [EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/automode.html): EKS launches, patches and removes the EC2 nodes itself as pods need them, and runs networking, EBS storage and the ALB controller for you. The module then skips the node groups, add-ons and ALB controller.

Nodes come from node pools. EKS enables two built-in ones, `general-purpose` and `system`, but they only launch amd64 C/M/R instances - so build amd64 (or multi-platform) images, and add your own `NodePool` for anything else, e.g. GPUs.

Auto Mode doesn't create an IngressClass, a default StorageClass or a GPU `NodePool`, so the module installs them - see [`modules/auto-mode`](modules/auto-mode/README.md).

## Project structure

```
(repo root)/             # The module itself
modules/                 # The sub-modules it's composed of, usable on their own
  ...
examples/                # Deployable example clusters and a demo app - see
                         # "Examples" below
```

## Examples

- [Demo cluster](examples/demo-k8s-cluster/README.md)
- [Demo cluster (auto mode)](examples/demo-k8s-cluster-auto/README.md)
- [Demo app](examples/demo-app/README.md)
