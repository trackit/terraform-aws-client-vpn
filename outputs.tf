output "kms_sops_arn" {
  value = aws_kms_key.sops.arn
}

output "decrypt_command" {
  value = "export SOPS_KMS_ARN=${aws_kms_key.sops.arn} && ${path.module}/scripts/decrypt.sh"
}

output "encrypt_command" {
  value = "export SOPS_KMS_ARN=${aws_kms_key.sops.arn} && ${path.module}/scripts/encrypt.sh"
}

output "server_certificate_arn" {
  value = aws_acm_certificate.server_cert.arn
}

output "env" {
  value = var.env
}

output "pki_folder_name" {
  value = local.provisioner_base_env["PKI_FOLDER_NAME"]
}

output "client_vpn_endpoint_id" {
  value = aws_ec2_client_vpn_endpoint.client_vpn.id
}

output "client_vpn_endpoint_arn" {
  value = aws_ec2_client_vpn_endpoint.client_vpn.arn
}

output "client_vpn_endpoint_dns_name" {
  value = aws_ec2_client_vpn_endpoint.client_vpn.dns_name
}

output "client_vpn_endpoint_status" {
  value = aws_ec2_client_vpn_endpoint.client_vpn.status
}