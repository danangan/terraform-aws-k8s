# demo-app

A Python FastAPI app. It stores orders on an EBS and an EFS volume.

## Deploy

```
cd examples/demo-app
./deploy.sh                          # demo-k8s-cluster
./deploy.sh ../demo-k8s-cluster-auto # Auto Mode cluster
```

It builds the image, pushes it to the cluster's ECR repo and installs the chart. The app is served on the ALB's DNS name:

```
ALB=$(kubectl get ingress app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

## Endpoints

| Endpoint | |
|---|---|
| `GET /` | Hello world |
| `GET /healthz` | Health check |
| `POST /orders/{ebs,efs}` | Store an order, one JSON file per order |
| `GET /orders/{ebs,efs}` | List the stored orders |

```
curl -X POST "http://$ALB/orders/ebs" -H 'content-type: application/json' -d '{"item":"coffee","quantity":2}'
curl "http://$ALB/orders/ebs"
```

- `ebs` - an EBS volume from the cluster's default StorageClass. It attaches to one node at a time, so the app runs a single replica
- `efs` - EFS, shared by every replica. Needs the `efs-sc` StorageClass

## Tear down

```
./teardown.sh
```

It deletes the EBS volume and the EFS access point along with the app. The EFS files stay on the file system.
