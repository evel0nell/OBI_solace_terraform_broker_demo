provider "solacebroker" {
  url      = var.broker_semp_url
  username = var.broker_username
  password = var.broker_password
  request_timeout_duration = "60s"
  request_min_interval     = "100ms"
  retries                  = 3
  retry_min_interval       = "3s"
  retry_max_interval       = "30s"
}
