# demo-k8s-cluster-auto

This demo cluster uses the auto mode.

## Deploy

```
cd examples/demo-k8s-cluster-auto
terraform init
terraform apply
aws eks update-kubeconfig --region us-east-1 --name demo-cluster-auto
```

It also creates an EFS file system and its `efs-sc` StorageClass ([`efs.tf`](efs.tf)), for the demo app's `/orders/efs` endpoint.

Then deploy the [demo app](../demo-app/README.md) with `./deploy.sh ../demo-k8s-cluster-auto`.

## Tear down

```
cd examples/demo-app && ./teardown.sh
cd ../demo-k8s-cluster-auto && terraform destroy
```
