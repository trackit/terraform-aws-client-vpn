variable "region" {
  description = "Region to work on."
  type        = string
}

variable "env" {  
  description = "The environment (e.g. prod, dev, stage)"
  type        = string
  default = "prod"
}

variable "clients" {  
  description = "A list of client certificate name"
  type        = list(string)
  default = ["client"]
}

variable "cert_issuer" { 
  description = "Common Name for CA Certificate"
  type        = string
  default = "CA"
}

variable "cert_server_name" { 
  description = "Name for the Server Certificate"
  type        = string
  default = "Server"
}

variable "aws_tenant_name" {
  description = "Name for the AWS Tenant"
  type        = string 
  default = "AWS"
}

variable "key_save_folder" {
  description = "Where to store keys (relative to pki folder)"
  type        = string 
  default     = "clientvpn_keys"
}

variable "subnet_id" {
  description = "The subnet ID to which we need to associate the VPN Client Connection."
  type        = string
}

variable "client_cidr_block" {
  description = "VPN CIDR block, must not overlap with VPC CIDR. Client cidr block must be at least a /22 range."
  type        = string
}

variable "target_cidr_block" {
  description = "The CIDR block to wich the client will have access to. Might be VPC CIDR's block for example."
  type        = string
}

variable "dns_servers" {
  description = "Information about the DNS servers to be used for DNS resolution. A Client VPN endpoint can have up to two DNS servers."
  type        = list(string)
  default     = null
}

variable "vpn_name" {
  description = "The name of the VPN Client Connection."
  type        = string
  default     = "VPN"
}

variable "cloudwatch_enabled" {
  description = "Indicates whether connection logging is enabled."
  type = bool
  default = true
}

variable "cloudwatch_log_group" {
  description = "The name of the cloudwatch log group."
  type        = string
  default = "vpn_endpoint_cloudwatch_log_group"
}

variable "cloudwatch_log_stream" {
  description = "The name of the cloudwatch log stream."
  type        = string
  default = "vpn_endpoint_cloudwatch_log_stream"
}

variable "aws_cli_profile_name" {
  description = "The name of the aws cli profile used in scripts"
  type        = string
  default     = "default"
}

variable "client_auth" {
  description = "the type of client authentication to be used : certificate-authentication / directory-service-authentication / federated-authentication"
  type        = string
  default     = "certificate-authentication"
}

variable "active_directory_id" {
  description = "The ID of the Active Directory to be used for authentication if type is directory-service-authentication"
  type        = string
  default     = null
}

variable "root_certificate_chain_arn" {
  description = "The ARN of the client certificate. The certificate must be signed by a certificate authority (CA) and it must be provisioned in AWS Certificate Manager (ACM). Only necessary when type is set to certificate-authentication."
  type        = string
  default = null
}

variable "saml_provider_arn" {
  description = "The ARN of the IAM SAML identity provider if type is federated-authentication"
  type        = string
  default     = null
}