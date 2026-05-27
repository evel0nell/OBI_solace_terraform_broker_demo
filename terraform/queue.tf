###############################################################################
# Queue inside the EXISTING Message VPN.
#
# The VPN itself is not declared here — we only reference it by name. If the
# VPN does not exist on the broker, `terraform apply` will fail at this point.
###############################################################################

resource "solacebroker_msg_vpn_queue" "this" {
  msg_vpn_name = solacebroker_msg_vpn.this.msg_vpn_name
  queue_name   = var.queue_name

  ingress_enabled = true
  egress_enabled  = true

  access_type         = var.queue_access_type
  permission          = var.queue_permission
  max_msg_spool_usage = var.queue_max_msg_spool_usage_mb

  owner = var.queue_owner != "" ? var.queue_owner : null
}
#
resource "solacebroker_msg_vpn_queue_subscription" "this" {
  for_each = toset(var.queue_subscriptions)

  msg_vpn_name       = solacebroker_msg_vpn_queue.this.msg_vpn_name
  queue_name         = solacebroker_msg_vpn_queue.this.queue_name
  subscription_topic = each.value
}
