locals {
  provisioner_base_env = {
    "CERT_ISSUER"     = var.cert_issuer
    "KEY_SAVE_FOLDER" = var.key_save_folder
    "SOPS_KMS_ARN"    = aws_kms_key.sops.arn
    "REGION"          = var.region
    "ENV"             = var.env
    "PKI_FOLDER_NAME" = "pki_${var.env}"
    "TARGET_CIDR"     = var.target_cidr_block
    "MODULE_PATH"     = path.module
    "CONCURRENCY"     = "true"
    "AWSCLIPROFILE"   = var.aws_cli_profile_name
  }

  clients = concat(var.clients)
}

resource "aws_kms_key" "sops" {
  description = "A KMS key used by SOPS to safely store easy-rsa secrets in Git."

  tags = {
    "Terraform" = "true"
  }
}

resource "null_resource" "server_certificate" {
  provisioner "local-exec" {
    environment = merge(local.provisioner_base_env, {
    })
    command = "${path.module}/scripts/prepare_easyrsa.sh"
  }
}

data "local_file" "server_private_key" {
  depends_on = [null_resource.server_certificate]
  filename = null_resource.server_certificate.id > 0 ? "pki_${var.env}/${var.key_save_folder}/server.key" : ""
}

data "local_file" "server_certificate_body" {
  depends_on = [null_resource.server_certificate]
  filename = null_resource.server_certificate.id > 0 ? "pki_${var.env}/${var.key_save_folder}/server.crt" : ""
}

data "local_file" "server_certificate_chain" {
  depends_on = [null_resource.server_certificate]
  filename = null_resource.server_certificate.id > 0 ? "pki_${var.env}/${var.key_save_folder}/ca.crt" : ""
}

resource "aws_acm_certificate" "server_cert" {
  depends_on = [null_resource.server_certificate]

  private_key       = data.local_file.server_private_key.content
  certificate_body  = data.local_file.server_certificate_body.content
  certificate_chain = data.local_file.server_certificate_chain.content

  lifecycle {
    ignore_changes = [options, private_key, certificate_body, certificate_chain]
  }
  tags = {
    Name = var.cert_server_name
  }
}

resource "null_resource" "client_certificate" {
  count      = length(local.clients)
  depends_on = [aws_acm_certificate.server_cert]

  provisioner "local-exec" {
    environment = merge(local.provisioner_base_env, {
      "CLIENT_CERT_NAME" = local.clients[count.index]
    })

    command = "${path.module}/scripts/create_client.sh"
  }
}

resource "aws_ec2_client_vpn_endpoint" "client_vpn" {
  depends_on             = [aws_acm_certificate.server_cert]
  description            = var.vpn_name
  server_certificate_arn = aws_acm_certificate.server_cert.arn
  client_cidr_block      = var.client_cidr_block
  split_tunnel           = true
  dns_servers            = var.dns_servers

  lifecycle {
    ignore_changes = [server_certificate_arn, authentication_options]
  }

  authentication_options {
    type                        = var.client_auth
    active_directory_id         = var.active_directory_id
    root_certificate_chain_arn  = var.root_certificate_chain_arn
    saml_provider_arn           = var.saml_provider_arn
  }

  connection_log_options {
    enabled               = var.cloudwatch_enabled
    cloudwatch_log_group  = aws_cloudwatch_log_group.client_vpn.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.client_vpn.name
  }

  provisioner "local-exec" {
    environment = merge(local.provisioner_base_env, {
      "CLIENT_VPN_ID" = self.id
    })
    command = "${path.module}/scripts/authorize_client.sh"
  }

  tags = {
    Name = var.vpn_name
  }
}

resource "null_resource" "export_clients_vpn_config" {
  depends_on = [null_resource.client_certificate]
  count      = length(local.clients)
  triggers = {
    client = local.clients[count.index]
  }

  provisioner "local-exec" {
    environment = merge(local.provisioner_base_env, {
      "CLIENT_VPN_ID"    = aws_ec2_client_vpn_endpoint.client_vpn.id,
      "CLIENT_CERT_NAME" = local.clients[count.index],
      "TENANT_NAME" = var.aws_tenant_name
    })
    command = "${path.module}/scripts/export_client_vpn_config.sh"
  }
}

resource "aws_ec2_client_vpn_network_association" "client_vpn" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client_vpn.id
  subnet_id              = var.subnet_id
}

resource "aws_cloudwatch_log_group" "client_vpn" {
  name = var.cloudwatch_log_group
}

resource "aws_cloudwatch_log_stream" "client_vpn" {
  name           = var.cloudwatch_log_stream
  log_group_name = aws_cloudwatch_log_group.client_vpn.name
}