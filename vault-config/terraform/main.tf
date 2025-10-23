terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.3.0"
    }
  }
}

# Provider is automatically configured by the
# VAULT_ADDR and VAULT_TOKEN env variables.

# 1. Enable the PKI secrets engine
resource "vault_mount" "pki_int" {
  path        = "pki"
  type        = "pki"
  description = "PKI for internal services"
  max_lease_ttl = "87600h" # 10 years
}

# 2. Define the Root Authority
resource "vault_pki_secret_backend_root_cert" "root_ca" {
  backend     = vault_mount.pki_int.path
  type        = "internal"
  common_name = "kind.local Root CA"
  ttl         = "87600h"
  format      = "pem"
  key_type    = "rsa"
  key_bits    = 4096
}

# 3. Configure the URLs for the CA and CRL
resource "vault_pki_secret_backend_config_urls" "config_urls" {
  backend = vault_mount.pki_int.path
  
  issuing_certificates = [
    "${vault_mount.pki_int.path}/ca"
  ]
  crl_distribution_points = [
    "${vault_mount.pki_int.path}/crl"
  ]

  depends_on = [vault_pki_secret_backend_root_cert.root_ca]
}
