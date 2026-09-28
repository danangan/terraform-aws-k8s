# cilium

Installs [Cilium](https://docs.cilium.io/en/stable/overview/intro/) as the cluster's CNI, replacing the VPC CNI and kube-proxy:

- [ENI IPAM](https://docs.cilium.io/en/stable/network/concepts/ipam/eni/): pods get VPC IPs from ENIs in `subnet_ids`, so the ALB (`target-type: ip`) and the EKS control plane reach them directly. The operator gets the EC2 permissions for this through EKS Pod Identity.
- [kube-proxy replacement](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/): Services are routed with eBPF instead of iptables.
- [WireGuard encryption](https://docs.cilium.io/en/stable/security/network/encryption-wireguard/) of pod-to-pod traffic between nodes, with UDP 51871 opened in the node security group.

Meant for new clusters - it doesn't migrate one running the VPC CNI.

Nodes can't become Ready without a CNI, so Cilium has to be installed before the node groups. The `node_labels` output depends on the Helm release - passing it to the `eks` sub-module's `node_labels` makes the node groups wait for Cilium.

## Inputs

| Name | Description | Default |
|---|---|---|
| `cluster_name` | Name of the EKS cluster | - |
| `cluster_endpoint` | Endpoint of the cluster's Kubernetes API - Cilium talks to it directly, since kube-proxy is replaced | - |
| `subnet_ids` | Subnets Cilium may create pod ENIs in | - |
| `node_security_group_id` | Security group shared by the nodes - opened for WireGuard between them | - |
| `chart_version` | Version of the `cilium` Helm chart | `1.20.2` |

## Outputs

| Name | Description |
|---|---|
| `node_labels` | `cni=cilium`, for every node group |
