###############################################################################
# Client Username — b3 client identity tied to the b3 client and ACL profiles.
###############################################################################

resource "solacebroker_msg_vpn_client_username" "b3" {
  msg_vpn_name    = solacebroker_msg_vpn.this.msg_vpn_name
  client_username = var.client_username

  password             = var.client_password
  client_profile_name  = solacebroker_msg_vpn_client_profile.this.client_profile_name
  acl_profile_name     = solacebroker_msg_vpn_acl_profile.b3.acl_profile_name

  subscription_manager_enabled                   = false
  guaranteed_endpoint_permission_override_enabled = false

  enabled = true
}
