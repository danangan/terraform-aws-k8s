# Examples

| Example | |
|---|---|
| [`demo-k8s-cluster/`](demo-k8s-cluster/) | Cluster on managed node groups, with Cilium |
| [`demo-k8s-cluster-auto/`](demo-k8s-cluster-auto/) | Cluster on [EKS Auto Mode](../README.md#eks-auto-mode) |
| [`demo-app/`](demo-app/) | FastAPI app with a Helm chart, for either cluster. Stores orders on EBS and EFS volumes |

The cluster examples use the local module (`source = "../.."`). In your own project, use `danangan/k8s/aws` from the registry.

Commands run from the repo root.

## Prerequisites

AWS CLI, Terraform >= 1.7.0, kubectl, Helm, and Docker or Podman.

Log in to AWS first, e.g. `aws login`, `aws sso login` or `aws configure`.

## Provision a cluster

### Managed node groups (`demo-k8s-cluster`)

```
cd examples/demo-k8s-cluster
terraform init
terraform apply
```

The first apply fails - run it again. See [the bootstrap catch](../README.md#the-bootstrap-catch).

It also creates an EFS file system and its `efs-sc` StorageClass ([`efs.tf`](demo-k8s-cluster/efs.tf)), for the demo app's `/orders/efs` endpoint.

### EKS Auto Mode (`demo-k8s-cluster-auto`)

```
cd examples/demo-k8s-cluster-auto
terraform init
terraform apply
aws eks update-kubeconfig --region us-east-1 --name demo-cluster-auto
kubectl apply -f auto-mode/
```

`auto-mode/` holds what Auto Mode doesn't create itself:

- `ingress-class.yaml` - the `alb` IngressClass. Required for any Ingress
- `storage-class.yaml` - a default, encrypted gp3 StorageClass
- `graviton-node-pool.yaml` - arm64 nodes. The built-in pools are amd64 only
- `gpu-node-pool.yaml` - `g4dn.xlarge` GPU nodes, tainted `gpu-workload=true:NoSchedule`

## Deploy the demo app

```
cd examples/demo-app
./deploy.sh                          # managed node group cluster
./deploy.sh ../demo-k8s-cluster-auto # Auto Mode cluster
```

It builds the image, pushes it to the cluster's ECR repo and installs the Helm chart. The app is served on the ALB's DNS name.

### Orders

The app stores orders on two volumes, one JSON file per order:

```
curl -X POST http://<alb-dns>/orders/ebs -H 'content-type: application/json' -d '{"item":"coffee","quantity":2}'
curl http://<alb-dns>/orders/ebs
```

- `/orders/ebs` - on an EBS volume from the cluster's default StorageClass. It attaches to one node at a time, so the app runs a single replica
- `/orders/efs` - on EFS, shared by every replica

The EFS volume needs the `efs-sc` StorageClass. `demo-k8s-cluster` creates it; on `demo-k8s-cluster-auto`, create a file system and the StorageClass yourself as shown in [EFS storage](../README.md#efs-storage), or the app's pod stays `Pending`.

`./teardown.sh` deletes the EBS volume and the EFS access point along with the app. The EFS files stay on the file system.

## Tear down

```
cd examples/demo-app
./teardown.sh

cd ../demo-k8s-cluster   # or ../demo-k8s-cluster-auto
terraform destroy
```

Run `./teardown.sh` before `terraform destroy`. It deletes the app's volumes: EBS volumes still claimed at destroy time are left behind, and the EFS file system can't be deleted while it still has access points.
