###############################################################################
# Client Profile — grants clients in the VPN permission to send and receive
# guaranteed (persistent) messages and to bind to endpoints (queues).
###############################################################################

resource "solacebroker_msg_vpn_client_profile" "this" {
  msg_vpn_name        = solacebroker_msg_vpn.this.msg_vpn_name
  client_profile_name = var.client_profile_name

  allow_guaranteed_msg_send_enabled      = true
  allow_guaranteed_msg_receive_enabled   = true
  allow_guaranteed_endpoint_create_enabled = false # as all queues are managed by terraform
}
