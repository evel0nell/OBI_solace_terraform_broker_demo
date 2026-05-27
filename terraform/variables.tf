###############################################################################
# Broker connection (SEMP v2)
###############################################################################

variable "broker_semp_url" {
  description = "HTTPS URL of the broker SEMP v2 endpoint, e.g. https://mr-abc.messaging.solace.cloud:943"
  type        = string

  validation {
    condition     = startswith(var.broker_semp_url, "https://")
    error_message = "broker_semp_url must use https:// to enforce TLS between Terraform and the broker."
  }
}

variable "broker_username" {
  description = "SEMP management user with permissions to manage queues and client cert authorities."
  type        = string
}

variable "broker_password" {
  description = "Password for broker_username. Prefer setting via SOLACEBROKER_PASSWORD env var or a sealed tfvars file."
  type        = string
  sensitive   = true
}

variable "broker_insecure_skip_verify" {
  description = "Skip TLS verification of the broker SEMP certificate. Use ONLY for dev/test brokers with self-signed certs."
  type        = bool
  default     = false
}

###############################################################################
# Message VPN — must already exist on the broker
###############################################################################

variable "msg_vpn_name" {
  description = "Name of the existing Message VPN to attach the queue to. This module does NOT create the VPN."
  type        = string
}

###############################################################################
# Queue
###############################################################################

variable "queue_name" {
  description = "Name of the queue to create inside msg_vpn_name."
  type        = string
}

variable "queue_access_type" {
  description = "Queue access type: exclusive or non-exclusive."
  type        = string
  default     = "exclusive"

  validation {
    condition     = contains(["exclusive", "non-exclusive"], var.queue_access_type)
    error_message = "queue_access_type must be one of: exclusive, non-exclusive."
  }
}

variable "queue_permission" {
  description = "Default non-owner permission on the queue: no-access, read-only, consume, modify-topic, delete."
  type        = string
  default     = "consume"
}

variable "queue_max_msg_spool_usage_mb" {
  description = "Maximum spool usage (MB) allowed for the queue."
  type        = number
  default     = 5000
}

variable "queue_owner" {
  description = "Optional client-username that owns the queue. Empty string = no owner override."
  type        = string
  default     = ""
}

variable "queue_subscriptions" {
  description = "List of topic subscription strings to attract messages onto the queue (e.g. [\"obi/orders/>\"])."
  type        = list(string)
  default     = []
}

###############################################################################
# Client Username
###############################################################################

variable "client_username" {
  description = "Client username for b3 clients connecting to the VPN."
  type        = string
}

variable "client_password" {
  description = "Password for the b3 client username."
  type        = string
  sensitive   = true
}

###############################################################################
# ACL Profile
###############################################################################

variable "acl_profile_name" {
  description = "Name of the ACL profile for b3 clients."
  type        = string
  default     = "b3-acl"
}

variable "b3_topic" {
  description = "Topic string b3 clients are allowed to publish to and subscribe from."
  type        = string
}

###############################################################################
# Client Profile
###############################################################################

variable "client_profile_name" {
  description = "Name of the client profile to create. Clients assigned this profile can send and receive guaranteed messages."
  type        = string
  default     = "tf-guaranteed"
}

