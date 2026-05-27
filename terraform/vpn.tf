###############################################################################
# Message VPN — managed resource (imported from the existing broker).
# After import cannot be deleted!
###############################################################################

resource "solacebroker_msg_vpn" "this" {
  msg_vpn_name = var.msg_vpn_name

  enabled = true

  # --- Auth ---
  authentication_basic_enabled = true
  authentication_basic_type    = "internal" # looks up in the internal database for the client username
  authentication_oauth_enabled = true


  # --- Capacity limits ---
  max_connection_count          = 100
  max_egress_flow_count         = 100
  max_endpoint_count            = 100
  max_ingress_flow_count        = 100
  max_kafka_broker_connection_count = 300
  max_msg_spool_usage           = 25000
  max_subscription_count        = 1000
  max_transacted_session_count  = 100
  max_transaction_count         = 500


  # --- REST ---
  service_rest_incoming_tls_enabled = true

  # # --- SMF / Web ---
  # service_smf_max_connection_count  = 100
  # service_web_max_connection_count  = 1000
  # service_web_plain_text_enabled    = false
}
