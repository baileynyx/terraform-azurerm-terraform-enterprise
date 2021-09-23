locals {
  replicated_base_config = {
    BypassPreflightChecks        = true
    DaemonAuthenticationPassword = random_string.password.result
    DaemonAuthenticationType     = "password"
    ImportSettingsFrom           = "/etc/ptfe-settings.json"
    LicenseFileLocation          = "/etc/${var.user_data_tfe_license_name}"
    TlsBootstrapHostname         = var.fqdn
    TlsBootstrapCert             = "/var/lib/waagent/${var.user_data_tfe_bootstrap_cert_name}.crt"
    TlsBootstrapKey              = "/var/lib/waagent/${var.user_data_tfe_bootstrap_key_name}.prv"
    TlsBootstrapType             = "server-path"
  }

  user_data_release_sequence = {
    ReleaseSequence = var.user_data_release_sequence
  }
}

locals {
  # Build TFE configuration in JSON format by merging partial config local variables
  release_sequence = var.user_data_release_sequence != null ? local.user_data_release_sequence : {}

  redis_configuration      = var.active_active ? local.redis_configs : {}
  tfe_configuration        = jsonencode(merge(local.base_configs, local.base_external_configs, local.external_azure_configs, local.redis_configuration))
  replicated_configuration = jsonencode(merge(local.replicated_base_config, local.release_sequence))
}

locals {
  # Build TFE user data / custom data / cloud init
  tfe_user_data = templatefile(
    "${path.module}/templates/tfe.sh.tpl",
    {
      # Configuration data
      replicated    = base64encode(local.replicated_configuration)
      settings      = base64encode(local.tfe_configuration)
      active_active = var.active_active
      fqdn          = var.fqdn

      # Secrets
      ca_cert_secret_name     = var.ca_cert_secret_name
      key_vault_name          = var.key_vault_name
      tfe_bootstrap_cert_name = var.user_data_tfe_bootstrap_cert_name
      tfe_bootstrap_key_name  = var.user_data_tfe_bootstrap_key_name
      tfe_license_name        = var.user_data_tfe_license_name
      tfe_license_secret_name = var.tfe_license_secret_name
      use_tls_kv_secrets      = var.user_data_use_kv_secrets

      # Proxy information
      proxy_ip   = var.proxy_ip
      proxy_port = var.proxy_port
      no_proxy = join(
        ",",
        concat(
          [
            "127.0.0.1",
            "169.254.169.254",
            ".azure.com",
            ".windows.net",
            ".microsoft.com",
          ],
          var.no_proxy
        )
      )
    }
  )
}

resource "random_string" "password" {
  length  = 16
  special = false
}

resource "random_id" "archivist_token" {
  byte_length = 16
}

resource "random_id" "cookie_hash" {
  byte_length = 16
}

resource "random_id" "enc_password" {
  byte_length = 16
}

resource "random_id" "install_id" {
  byte_length = 16
}

resource "random_id" "internal_api_token" {
  byte_length = 16
}

resource "random_id" "root_secret" {
  byte_length = 16
}

resource "random_id" "registry_session_secret_key" {
  byte_length = 16
}

resource "random_id" "registry_session_encryption_key" {
  byte_length = 16
}

resource "random_id" "user_token" {
  byte_length = 16
}

locals {
  base_configs = {
    hostname = {
      value = var.fqdn
    }

    installation_type = {
      value = "production"
    }

    production_type = {
      value = "external"
    }

    archivist_token = {
      value = random_id.archivist_token.hex
    }

    cookie_hash = {
      value = random_id.cookie_hash.hex
    }

    enc_password = {
      value = random_id.enc_password.hex
    }

    extra_no_proxy = {
      value = ""
    }

    iact_subnet_list = {
      value = join(",", var.user_data_iact_subnet_list)
    }

    install_id = {
      value = random_id.install_id.hex
    }

    internal_api_token = {
      value = random_id.internal_api_token.hex
    }

    registry_session_encryption_key = {
      value = random_id.registry_session_encryption_key.hex
    }

    registry_session_secret_key = {
      value = random_id.registry_session_secret_key.hex
    }

    root_secret = {
      value = random_id.root_secret.hex
    }

    trusted_proxies = {
      value = join(",", var.user_data_trusted_proxies)
    }

    user_token = {
      value = random_id.user_token.hex
    }
  }

  base_external_configs = {
    enable_active_active = {
      value = var.active_active ? "1" : "0"
    }

    pg_dbname = {
      value = var.user_data_pg_dbname
    }

    pg_netloc = {
      value = var.user_data_pg_netloc
    }

    pg_password = {
      value = var.user_data_pg_password
    }

    pg_user = {
      value = var.user_data_pg_user
    }
  }

  redis_configs = {
    redis_host = {
      value = var.user_data_redis_host
    }

    redis_pass = {
      value = var.user_data_redis_pass
    }

    redis_port = {
      value = var.user_data_redis_port
    }

    redis_use_password_auth = {
      value = var.redis_enable_authentication == true ? "1" : "0"
    }

    redis_use_tls = {
      value = var.user_data_redis_use_tls == true ? "1" : "0"
    }
  }

  external_azure_configs = {
    azure_account_name = {
      value = var.user_data_azure_account_name
    }

    azure_account_key = {
      value = var.user_data_azure_account_key
    }

    azure_container = {
      value = var.user_data_azure_container_name
    }

    placement = {
      value = "placement_azure"
    }
  }
}
