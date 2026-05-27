###############################################################################
# ACL Profile for b3 — restricts publish/subscribe to the declared exceptions.
# Client connect is allowed; all topic traffic is denied by default.
###############################################################################

resource "solacebroker_msg_vpn_acl_profile" "b3" {
  msg_vpn_name     = solacebroker_msg_vpn.this.msg_vpn_name
  acl_profile_name = var.acl_profile_name

  client_connect_default_action  = "allow"
  publish_topic_default_action   = "disallow"
  subscribe_topic_default_action = "disallow"
}

resource "solacebroker_msg_vpn_acl_profile_publish_topic_exception" "b3_masterdata" {
  msg_vpn_name                   = solacebroker_msg_vpn_acl_profile.b3.msg_vpn_name
  acl_profile_name               = solacebroker_msg_vpn_acl_profile.b3.acl_profile_name
  publish_topic_exception        = var.b3_topic
  publish_topic_exception_syntax = "smf"
}

resource "solacebroker_msg_vpn_acl_profile_subscribe_topic_exception" "b3_masterdata" {
  msg_vpn_name                     = solacebroker_msg_vpn_acl_profile.b3.msg_vpn_name
  acl_profile_name                 = solacebroker_msg_vpn_acl_profile.b3.acl_profile_name
  subscribe_topic_exception        = var.b3_topic
  subscribe_topic_exception_syntax = "smf"
}
