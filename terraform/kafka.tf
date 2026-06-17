
resource "solacebroker_msg_vpn_kafka_receiver" "local" {

  msg_vpn_name        = solacebroker_msg_vpn.this.msg_vpn_name
  kafka_receiver_name = var.kafka_receiver_name

  bootstrap_address_list = var.kafka_bootstrap_servers

  enabled = true

  authentication_scheme = "none"
  transport_tls_enabled = false

  group_id              = var.kafka_receiver_group_id
  group_membership_type = "dynamic"
}

# Binding: Kafka topic "external.system" → Solace topic "external.system"
resource "solacebroker_msg_vpn_kafka_receiver_topic_binding" "external_system" {

  msg_vpn_name        = solacebroker_msg_vpn.this.msg_vpn_name
  kafka_receiver_name = solacebroker_msg_vpn_kafka_receiver.local.kafka_receiver_name
  topic_name          = "external.system"

  enabled        = true
  initial_offset = "beginning"
  local_topic    = "external.system"
}

# Queue for the external-system bridge output.
resource "solacebroker_msg_vpn_queue" "external_system" {
  msg_vpn_name = solacebroker_msg_vpn.this.msg_vpn_name
  queue_name   = "external.system"

  ingress_enabled = true
  egress_enabled  = true

  access_type         = "exclusive"
  permission          = "consume"
  max_msg_spool_usage = var.queue_max_msg_spool_usage_mb
}

resource "solacebroker_msg_vpn_queue_subscription" "external_system" {
  msg_vpn_name       = solacebroker_msg_vpn_queue.external_system.msg_vpn_name
  queue_name         = solacebroker_msg_vpn_queue.external_system.queue_name
  subscription_topic = "external/system/>"
}

# ---------------------------------------------------------------------------
# Kafka Sender  (Solace → Kafka)
# ---------------------------------------------------------------------------

resource "solacebroker_msg_vpn_kafka_sender" "local" {
  count = var.kafka_enabled ? 1 : 0

  msg_vpn_name      = solacebroker_msg_vpn.this.msg_vpn_name
  kafka_sender_name = var.kafka_sender_name

  bootstrap_address_list = var.kafka_bootstrap_servers

  enabled = true

  authentication_scheme = "none"
  transport_tls_enabled = false
}

# Binding: Solace queue "b3.collect" → Kafka topic "b3.kafka.test.collect"
resource "solacebroker_msg_vpn_kafka_sender_queue_binding" "b3_collect" {
  count = var.kafka_enabled ? 1 : 0

  msg_vpn_name      = solacebroker_msg_vpn.this.msg_vpn_name
  kafka_sender_name = solacebroker_msg_vpn_kafka_sender.local[0].kafka_sender_name
  queue_name        = solacebroker_msg_vpn_queue.this.queue_name

  enabled      = true
  remote_topic = "b3.kafka.test.collect"
  ack_mode     = "all"

  partition_scheme = "random"
}
