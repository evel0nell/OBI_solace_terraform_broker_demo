# Solace ↔ Kafka Bridge Demo (Terraform)

Terraform configuration that provisions a Solace PubSub+ Message VPN setup (queue, client
username, ACL/client profiles) and a **Kafka Bridge** (Receiver + Sender) connecting Solace
to a local Apache Kafka cluster. The Kafka cluster runs in Docker and is exposed to the
broker through a raw‑TCP tunnel.

```
┌──────────────┐    SEMP v2 (HTTPS:943)    ┌─────────────────────┐
│  Terraform   │ ────────────────────────▶ │  Solace PubSub+      │
└──────────────┘                           │  Broker (Cloud)      │
                                           └─────────┬───────────┘
                                Kafka protocol (TCP) │  Receiver ⇄ Sender
                                                     ▼
                              ┌────────────────────────────────────┐
                              │  TCP tunnel (bore.pub:<port>)        │
                              └─────────────────┬────────────────────┘
                                                ▼
                              ┌────────────────────────────────────┐
                              │  Kafka (Docker, KRaft) :9093 EXTERNAL│
                              └────────────────────────────────────┘
```

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | `>= 1.5.0` | Provisioning (see `terraform/versions.tf`) |
| Docker + Compose | recent | Local Kafka cluster (`docker-compose.yml`) |
| A TCP tunnel | — | Expose local Kafka to the cloud broker (`bore`, `rathole`, `frp`, …) |
| Solace PubSub+ broker | SEMP v2 | Cloud or self‑hosted broker with an **existing** Message VPN |

The Terraform provider [`solaceproducts/solacebroker`](https://registry.terraform.io/providers/solaceproducts/solacebroker/latest)
(`~> 1.0`) is downloaded automatically by `terraform init`.

> **Note:** This config references an **existing** Message VPN — it does not create one.
> `terraform apply` fails if `msg_vpn_name` does not exist on the broker.

---

## Credentials / API keys required for `terraform apply`

The broker is managed over **SEMP v2**, which authenticates the Terraform provider. Supply
credentials **via environment variables** — never commit them to `terraform.tfvars`.

> 🔒 **Security:** `*.tfstate` and `*.auto.tfvars` are git‑ignored. Keep secrets in
> environment variables or a secret manager (Vault, AWS Secrets Manager, Doppler). Prefer
> a least‑privilege SEMP user scoped to the target VPN over a global admin.

### Option A — Basic auth (username + password)

The `solacebroker` provider reads these standard environment variables:

```bash
export SOLACEBROKER_USERNAME="management-user"     # maps to provider `username`
export SOLACEBROKER_PASSWORD="••••••••"            # maps to provider `password`
# Optional — overrides var.broker_semp_url:
# export SOLACEBROKER_URL="https://mr-abc.messaging.solace.cloud:943"
```

Then put only the **non‑secret** connection values in `terraform.tfvars`:

```hcl
broker_semp_url = "https://mr-abc.messaging.solace.cloud:943"
broker_username = "management-user"   # or rely solely on the env var
```

### Option B — Bearer token (OAuth)

If your broker uses OAuth, authenticate with a bearer token instead of a password:

```bash
export SOLACEBROKER_BEARER_TOKEN="eyJhbGciOi..."   # provider `bearer_token`
```

| Env var | Provider attribute | Required | Notes |
|---------|--------------------|----------|-------|
| `SOLACEBROKER_USERNAME` | `username` | Option A | SEMP management user |
| `SOLACEBROKER_PASSWORD` | `password` | Option A | **Secret** — env var only |
| `SOLACEBROKER_BEARER_TOKEN` | `bearer_token` | Option B | **Secret** — OAuth token, mutually exclusive with password |
| `SOLACEBROKER_URL` | `url` | optional | Overrides `var.broker_semp_url` |

There is also a `client_password` variable (for the provisioned `client_username`) — set it
as a sealed/`.auto.tfvars` value or feed it from your secret manager. It is marked
`sensitive` so it never prints in plan output.

> **Solace Cloud tip:** find the SEMP URL and management credentials under
> **Cluster Manager → <service> → Connect → Management (SEMP)** or under
> **Manage → Broker Manager / SEMP** for the REST management role.

---

## Quick start

```bash
# 1. Start the local Kafka cluster + a TCP tunnel to the EXTERNAL listener (:9093)
bore local 9093 --to bore.pub          # prints e.g.  listening at bore.pub:47583
KAFKA_EXTERNAL_HOST=bore.pub KAFKA_EXTERNAL_PORT=47583 ./scripts/start.sh

# 2. Configure Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars   # then edit values
export SOLACEBROKER_PASSWORD="••••••••"         # secret via env var

# 3. Apply
terraform init
terraform plan
terraform apply
```




## Local Topic Expression — substitution examples

The Kafka **Receiver** forwards Kafka records into the Solace VPN. Because a Kafka topic
name is often not a good Solace topic, you set a **substitution expression** as the binding's
**Local Topic** (`local_topic` on `solacebroker_msg_vpn_kafka_receiver_topic_binding`) to
build the SMF topic dynamically from each record's fields.

Expressions are delimited by `${ ... }`. Functions applicable to a Kafka **Receiver**:

| Function | Returns |
|----------|---------|
| `kafkaTopic([N, separator])` | The source Kafka topic (optionally the Nth segment split by `separator`) |
| `kafkaPartitionNumber()` | Partition number the message came from |
| `kafkaPartitionOffset()` | Partition offset of the message |
| `kafkaPartitionKey()` / `kafkaPartitionKeyAsString()` | Kafka message key (bytes / string) |
| `kafkaTimestamp()` | Kafka message timestamp |
| `kafkaHeader(name)` / `kafkaHeaderAsString(name)` | A Kafka header value (bytes / string) |
| `replace(source, old, new [, count])` | String substitution |
| `withDefault(value, default)` | `value`, or `default` when `value` is empty |
| `utcDate()`, `utcYear()`, `utcMonth()`, `utcDay()` … | UTC date/time parts (for date‑partitioned topics) |
| `uuid()` / `UUID()`, `base64()`, `hex()` | UUID / encoding helpers |

### Examples

```hcl
# 1. Dotted Kafka hierarchy → Solace level hierarchy
#    "a.b.c"  ->  "a/b/c"   (the canonical Solace example)
local_topic = "${replace(kafkaTopic(), \".\", \"/\")}"

# 2. Namespace + original topic
#    -> "kafka/external.system"
local_topic = "kafka/${kafkaTopic()}"

# 3. Embed partition and offset for traceability / replay
#    -> "kafka/external.system/p/3/o/10421"
local_topic = "kafka/${kafkaTopic()}/p/${kafkaPartitionNumber()}/o/${kafkaPartitionOffset()}"

# 4. Route by message key (e.g. tenant or entity id)
#    -> "orders/by-key/customer-42"
local_topic = "orders/by-key/${kafkaPartitionKeyAsString()}"

# 5. Promote a Kafka header into the topic, with a fallback
#    -> "events/DE"  (or "events/unknown" if the header is absent)
local_topic = "events/${withDefault(kafkaHeaderAsString(\"region\"), \"unknown\")}"

# 6. Date‑partitioned archive topic from the message timestamp
#    -> "archive/2026/06/17/external.system"
local_topic = "archive/${utcYear()}/${utcMonth()}/${utcDay()}/${kafkaTopic()}"
```



---

## What gets created

| File | Resource |
|------|----------|
| `vpn.tf` | Message VPN (managed/imported — **cannot be deleted** after import) |
| `queue.tf` | Queue + topic subscriptions |
| `kafka_example_queues.tf` | Per example: Receiver topic binding + queue + subscription |
| `client_username.tf` | Client username for b3 clients |
| `acl_profile.tf` | ACL profile + publish/subscribe exceptions |
| `client_profile.tf` | Client profile (guaranteed messaging) |
| `kafka.tf` | Kafka Receiver (Kafka→Solace) + Sender (Solace→Kafka) and their bindings |

---

## Documentation

- **Kafka Bridging Overview** — https://docs.solace.com/Features/Kafka-Bridging/Kafka-Bridging-Overview.htm
- Substitution Expressions Overview — https://docs.solace.com/Messaging/Substitution-Expressions-Overview.htm
- Configuring Kafka Bridging (CLI) — https://docs.solace.com/Features/Kafka-Bridging/Kafka-Bridging-Setup-Overview.htm
- Configuring Kafka Bridging (Broker Manager) — https://docs.solace.com/Admin/Broker-Manager/config-kafka-bridge.htm
- Monitoring Kafka Bridges — https://docs.solace.com/Features/Kafka-Bridging/Kafka-Bridging-Monitor.htm
- Terraform provider (`solacebroker`) — https://registry.terraform.io/providers/solaceproducts/solacebroker/latest/docs
