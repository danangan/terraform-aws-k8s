# demo-k8s-cluster

## Deploy

```
cd examples/demo-k8s-cluster
terraform init
terraform apply
aws eks update-kubeconfig --region us-east-1 --name demo-cluster
```

Optionally, you can deploy the [demo-app](../demo-app/README.md).

## Tear down

If you deployed the demo-app into the cluster, first you need to uninstall the demo-app first:

```
cd examples/demo-app && ./teardown.sh
```

And then you can destroy:
```
cd ../demo-k8s-cluster && terraform destroy
```

Uninstalling the demo-app first is necessary, otherwise its EBS volume is left behind, and the EFS file system can't be deleted while the app's access point is still on it.
