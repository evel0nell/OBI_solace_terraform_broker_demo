###############################################################################
# Example queues for the Kafka Receiver "Local Topic Expression" patterns.
#
# Each entry mirrors one substitution-expression example from the README:
#   - `local_topic`  is the expression you would set on a Kafka Receiver topic
#                    binding; the Receiver publishes each record onto the Solace
#                    topic this produces.
#   - `subscription` is the topic subscription that attracts those messages onto
#                    the corresponding demo queue.
#
# HCL escaping: a literal Solace "${...}" expression is written "$${...}" here so
# Terraform passes it through verbatim instead of interpolating it. The comment
# after each line shows the resulting Solace topic for an example record
# (partition 3, offset 10421, key "customer-42").
#
# Two Kafka source topics only — "orders" and "payments". A Receiver allows just
# ONE binding per Kafka topic, so each example maps to a distinct topic. Create
# the topics with scripts/create-topics.sh (or see the command in the README).
###############################################################################

locals {
  # `kafka_topic`  = Kafka source topic the Receiver consumes.
  # `local_topic`  = substitution expression that builds the Solace topic.
  # `subscription` = topic subscription that attracts the result onto the queue.
  kafka_topic_examples = {
    # Route by message key (e.g. tenant or entity id)
    orders = {
      kafka_topic  = "orders"
      local_topic  = "orders/by-key/$${kafkaPartitionKeyAsString()}" # -> orders/by-key/customer-42
      subscription = "orders/by-key/>"
    }

    # Embed partition and offset for traceability / replay
    payments = {
      kafka_topic  = "payments"
      local_topic  = "payments/p/$${kafkaPartitionNumber()}/o/$${kafkaPartitionOffset()}" # -> payments/p/3/o/10421
      subscription = "payments/p/*/o/*"
    }
  }
}

# One queue per example.
resource "solacebroker_msg_vpn_queue" "kafka_example" {
  for_each = var.kafka_example_queues_enabled ? local.kafka_topic_examples : {}

  msg_vpn_name = solacebroker_msg_vpn.this.msg_vpn_name
  queue_name   = "${var.kafka_example_queue_prefix}.${each.key}"

  ingress_enabled = true
  egress_enabled  = true

  access_type         = "exclusive"
  permission          = "consume"
  max_msg_spool_usage = var.queue_max_msg_spool_usage_mb
}

# Matching topic subscription that attracts the Receiver's output onto the queue.
resource "solacebroker_msg_vpn_queue_subscription" "kafka_example" {
  for_each = var.kafka_example_queues_enabled ? local.kafka_topic_examples : {}

  msg_vpn_name       = solacebroker_msg_vpn_queue.kafka_example[each.key].msg_vpn_name
  queue_name         = solacebroker_msg_vpn_queue.kafka_example[each.key].queue_name
  subscription_topic = each.value.subscription
}

# Kafka Receiver topic binding: consume `kafka_topic` and publish each record onto
# the Solace topic built by the `local_topic` substitution expression, which the
# matching queue above then attracts.
resource "solacebroker_msg_vpn_kafka_receiver_topic_binding" "kafka_example" {
  for_each = var.kafka_example_queues_enabled ? local.kafka_topic_examples : {}

  msg_vpn_name        = solacebroker_msg_vpn.this.msg_vpn_name
  kafka_receiver_name = solacebroker_msg_vpn_kafka_receiver.local.kafka_receiver_name

  topic_name     = each.value.kafka_topic
  local_topic    = each.value.local_topic
  enabled        = true
  initial_offset = "beginning"
}
