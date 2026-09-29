# nvidia-device-plugin

Installs the [NVIDIA device plugin](https://github.com/NVIDIA/k8s-device-plugin) on the GPU node group, so its nodes advertise `nvidia.com/gpu` and pods can request GPUs. The EKS-optimized AL2023 NVIDIA AMI has the driver but [not the device plugin](https://docs.aws.amazon.com/eks/latest/userguide/ml-eks-optimized-ami.html#eks-amis-nvidia-al2023).

The plugin runs only on nodes of `gpu_instance_type`. It tolerates the `nvidia.com/gpu` taint through the chart's defaults, so the GPU node group needs that taint (the module's default) rather than a custom one. The root module installs it unless `enable_auto_mode = true` - Auto Mode's GPU nodes come with the plugin. Needs the `helm` provider configured.

## Inputs

| Name | Description | Default |
|---|---|---|
| `gpu_instance_type` | Instance type of the GPU node group - the plugin only runs on those nodes | `g4dn.xlarge` |
| `chart_version` | Version of the `nvidia-device-plugin` Helm chart | `0.20.1` |
