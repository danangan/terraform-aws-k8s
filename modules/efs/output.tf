output "iam_role_arn" {
  description = "ARN of the IAM role the EFS CSI driver's controller runs as"
  value       = aws_iam_role.efs_csi_driver.arn
}
