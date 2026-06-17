
broker_semp_url             = "https://ps-showcase-demo.messaging.solace.cloud:943" # https://BROKER_HOSTNAME:943
broker_username             = "mission-control-manager"
broker_password             = "schr4gcs4eld102l92akknh9gu" # Cloud control plane -> cluster manager -> broker -> connect -> SEMP - REST API -> mission control manager password


msg_vpn_name                 = "ps-showcase-demo"
queue_name                   = "b3.collect"
queue_access_type            = "exclusive"
// queue_permission             = "consume"
queue_max_msg_spool_usage_mb = 5000
queue_subscriptions          = ["obi/masterdata/b3-itemhierarchy-category/>"]

client_username              = "b3-user"
client_password              = "password" # client basic auth für das Testen

client_profile_name          = "b3-client"

acl_profile_name             = "b3-acl"
b3_topic                     = "obi/masterdata/b3-itemhierarchy-category/create/v1/DE/de_CH/682" # OBI topic Pfad

kafka_enabled           = true
kafka_bootstrap_servers = "bore.pub:47583"