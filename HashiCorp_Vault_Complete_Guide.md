# HashiCorp Vault — Complete Topic Guide (Beginner → Advanced)

A detailed reference covering every Vault topic from fundamentals to advanced enterprise and DevOps interview-focused material.

---

## 1. Vault Fundamentals

### What is Vault?
HashiCorp Vault is a tool for securely storing, accessing, and managing secrets such as API keys, passwords, certificates, and encryption keys. Instead of hardcoding credentials in source code, configuration files, or environment variables, applications and users retrieve them on-demand from Vault through an authenticated API call. Vault centralizes secret storage behind a security barrier, encrypts everything at rest, and provides a unified interface (CLI, UI, API) to manage access across many systems and clouds.

### Why Vault?
Organizations adopt Vault to solve several recurring security problems: secrets scattered across config files and source repos, no audit trail of who accessed what secret and when, long-lived static credentials that are rarely rotated, and inconsistent access control across different platforms (AWS, databases, Kubernetes, etc.). Vault addresses these by providing centralized secret storage, fine-grained access policies, detailed audit logging, short-lived dynamically generated credentials, and encryption-as-a-service so applications never need to manage their own cryptographic keys.

### Secrets Management Concepts
Secrets management is the practice of securely storing, distributing, rotating, and revoking sensitive data (passwords, tokens, certificates, encryption keys). Core concepts include the principle of least privilege (only grant access to what's needed), secret lifecycle management (creation, rotation, expiration, revocation), centralization (a single source of truth instead of secrets spread across systems), and auditability (every access is logged for compliance and forensic purposes). Vault implements all of these through its secrets engines, policies, and audit devices.

### Static vs Dynamic Secrets
Static secrets are fixed credentials that exist independently of Vault — for example, a database password that an administrator created, which Vault simply stores and serves (KV secrets engine). They don't change unless someone manually rotates them. Dynamic secrets, by contrast, are generated on-demand by Vault each time they're requested. When an application asks for database credentials, Vault creates a brand-new database user with a unique username/password and a time-limited lease. When the lease expires, Vault automatically revokes that user. Dynamic secrets dramatically reduce the blast radius of credential leaks because each credential is unique, short-lived, and tied to a specific lease that can be revoked instantly.

### Vault Use Cases
Common use cases include centralized secrets storage for applications and microservices, dynamic database credential generation, encryption-as-a-service for applications that need to encrypt data without managing their own keys (Transit engine), PKI/certificate issuance and management for internal services, identity-based access brokering across cloud providers (AWS/Azure/GCP), Kubernetes secret injection for pods, SSH credential management for one-time SSH access, and compliance/audit logging for regulatory requirements (PCI-DSS, HIPAA, SOC 2).

### Vault Components
Vault's architecture is built from several core components: the **storage backend** (persists encrypted data — e.g., Raft, Consul, file), the **security barrier** (the encryption layer that sits between the storage backend and everything else, ensuring all data is encrypted before it touches disk), the **HTTP API** (the interface all clients use, including the CLI and UI), **secrets engines** (plugins that store, generate, or encrypt data — KV, Database, PKI, Transit, etc.), **auth methods** (plugins that verify identity — Token, AppRole, Kubernetes, LDAP, etc.), the **token store** (manages all issued tokens), **the audit broker** (dispatches request/response logs to audit devices), and **policies** (ACL rules that define what authenticated identities can do).

### Vault Architecture
At a high level, a client sends a request to Vault's HTTP API. The request first passes through an auth method (if not already authenticated) to establish identity, then the **policy engine** checks the associated ACL policies to determine whether the action is permitted. If allowed, the request is routed to the relevant secrets engine, which performs the operation (e.g., generate a dynamic credential, read/write a KV value, encrypt data). All data that needs to be persisted passes through the **security barrier**, which encrypts it using the barrier key before writing it to the storage backend (Raft, Consul, etc.). Every request and response can also be sent to configured **audit devices** for logging. In HA deployments, multiple Vault server nodes form a cluster with one active node handling all reads/writes and standby nodes ready to take over via leader election.

### Vault Enterprise vs OSS
Vault Open Source (OSS) provides the core secrets management, dynamic secrets, encryption, identity, and policy capabilities free of charge. Vault Enterprise adds features aimed at large organizations: **Namespaces** (multi-tenancy — isolated environments within a single Vault cluster), **Performance Replication** and **Disaster Recovery (DR) Replication** (multi-datacenter/multi-region setups), **Sentinel** (fine-grained, logic-based policy-as-code beyond standard ACLs), **HSM integration** for auto-unseal and key management, **Performance Standby Nodes** (read scaling), **MFA**, **Control Groups**, and advanced licensing/support options. Enterprise is typically chosen by organizations needing multi-region resilience, regulatory compliance controls, or large-scale multi-team isolation.

### Vault Deployment Models
Vault can be deployed in several models: **single-node dev mode** (in-memory, unsealed automatically, for local testing only — never production), **single-node production** (one server with persistent storage, suitable for small/non-critical workloads but with no HA), **HA cluster with Integrated Storage (Raft)** (multiple nodes forming a Raft consensus cluster, providing automatic failover), **HA cluster with Consul storage backend** (an older but still-supported pattern using Consul for storage and leader election), and **multi-region Enterprise deployments** using Performance and DR replication to link clusters across geographic regions. Cloud-managed offerings (e.g., HCP Vault) also exist, where HashiCorp operates the infrastructure.

### Vault UI Overview
The Vault Web UI is a browser-based graphical interface that mirrors most CLI/API functionality. It allows users to log in via any enabled auth method, browse and manage secrets engines, create and edit KV secrets, view and edit policies, manage authentication methods and their configuration, inspect and revoke tokens and leases, view the identity store (entities, groups, aliases), and review system status (seal status, HA status, replication status for Enterprise). The UI is especially useful for administrators performing one-off configuration tasks and for end users browsing secrets they have access to, but production automation typically relies on the CLI/API.

### Vault CLI Overview
The `vault` command-line tool is the primary way administrators and operators interact with Vault. Key command groups include `vault server` (start a Vault server), `vault operator` (initialize, unseal, manage raft/HA), `vault login` (authenticate using any auth method), `vault kv` (read/write/list KV secrets), `vault secrets` (enable/disable/configure secrets engines), `vault auth` (enable/disable/configure auth methods), `vault policy` (write/read/list ACL policies), `vault token` (create, lookup, revoke, renew tokens), `vault lease` (renew/revoke leases), and `vault audit` (enable/disable audit devices). The CLI communicates with Vault over its HTTP API, so anything doable via CLI is also doable via direct API calls.

### Vault API Overview
Vault exposes a comprehensive RESTful HTTP API, and essentially every CLI command and UI action is simply a wrapper around an API call. The API is organized by path, such as `/v1/sys/*` for system operations (seal status, mounts, policies, audit), `/v1/auth/*` for authentication method operations, and `/v1/<mount-path>/*` for secrets engine operations (e.g., `/v1/secret/data/myapp` for a KV v2 secret). Requests are authenticated using a token passed in the `X-Vault-Token` header. The API returns JSON responses and supports standard HTTP verbs (GET for read, POST/PUT for write, LIST for listing, DELETE for delete). This API-first design means Vault integrates naturally into automation pipelines, custom applications, and infrastructure-as-code tools like Terraform.

---

## 2. Vault Installation & Setup

### Install Vault on Linux
Vault is distributed as a single statically-linked binary, making installation straightforward. On Debian/Ubuntu systems, HashiCorp provides an APT repository: you add the HashiCorp GPG key and repository, then run `apt-get install vault`. On RHEL/CentOS, an equivalent YUM repository is available. Alternatively, you can download the appropriate `.zip` binary for your architecture directly from HashiCorp's release page, unzip it, and place the `vault` binary in a directory on your `PATH` (e.g., `/usr/local/bin`). After installation, running `vault -v` confirms the version, and `vault server -config=/etc/vault.d/vault.hcl` starts the server using a configuration file. For production, Vault is typically run as a systemd service with a dedicated non-root user, proper file permissions, and `mlock` capability granted so secret material isn't swapped to disk.

### Dev Mode vs Production Mode
**Dev mode** (`vault server -dev`) starts an in-memory, single-node Vault instance that is automatically initialized and unsealed, uses HTTP (not HTTPS) by default, and provides a root token printed to the console. It's extremely convenient for local testing and learning but is completely unsuitable for production: all data is lost on restart, there's no real security barrier persistence, and TLS is disabled. **Production mode** requires an explicit configuration file specifying a persistent storage backend (Raft, Consul, etc.), a TLS listener configuration, and requires the operator to manually run `vault operator init` and `vault operator unseal` after starting the server. Production deployments also typically integrate with auto-unseal mechanisms, run behind load balancers, and are deployed as HA clusters.

### Vault Configuration File
Vault's server configuration is written in HCL (HashiCorp Configuration Language) or JSON, typically saved as `vault.hcl` or `config.hcl`. Key configuration blocks include `storage` (defines the backend, e.g., `storage "raft" { path = "/vault/data" node_id = "node1" }`), `listener` (defines network listeners and TLS settings, e.g., `listener "tcp" { address = "0.0.0.0:8200" tls_cert_file = "..." tls_key_file = "..." }`), `seal` (configures auto-unseal mechanisms like AWS KMS), `api_addr` and `cluster_addr` (addresses used for client communication and inter-node clustering), `ui = true` (enables the web UI), and `disable_mlock` (generally should remain false in production, but sometimes needed in containers). The configuration file is passed to `vault server -config=<path>` at startup.

### Storage Backends
The storage backend is where Vault persists its encrypted data. Vault supports many backends, but the primary supported choices are **Integrated Storage (Raft)** — Vault's built-in, recommended storage solution that requires no external dependency and provides HA via the Raft consensus protocol — and **Consul** — an older pattern where HashiCorp's Consul service mesh/KV store handles storage and leader election. Other backends (filesystem, various cloud object stores, databases like PostgreSQL or MySQL) exist but are typically used only for single-node, non-HA, or legacy deployments. Critically, all data written to any backend is already encrypted by Vault's security barrier before it's stored, so the backend itself doesn't need to provide encryption — it just needs to provide durable, available storage.

### File Storage
The `file` storage backend stores Vault's encrypted data as files on the local filesystem of the server. It's simple to configure (`storage "file" { path = "/vault/data" }`) and works well for single-node development or small non-critical deployments. However, it does **not** support high availability — only one Vault node can use a given file storage path, so if that node fails, Vault becomes unavailable until it's restored. For this reason, file storage is generally discouraged for production unless paired with external HA mechanisms, and Raft (Integrated Storage) is now the recommended default even for single-node setups since it provides an easy upgrade path to HA.

### Integrated Storage (Raft)
Integrated Storage uses the **Raft consensus algorithm** to replicate Vault's data across multiple server nodes without requiring any external storage system like Consul. Each Vault node stores a full copy of the encrypted data in its local Raft log and state, and Raft ensures all nodes agree on the current state through leader election and log replication. One node is elected **leader (active)** and handles all writes; other nodes are **followers (standby)** that replicate the leader's log and can take over if the leader fails. This is configured with `storage "raft" { path = "..." node_id = "..." retry_join { ... } }`. Integrated Storage is HashiCorp's recommended approach for new deployments because it simplifies the architecture (no separate Consul cluster to operate) while still providing strong consistency and automatic failover.

### Consul Storage
Before Integrated Storage existed, **Consul** was the standard recommended storage backend for HA Vault deployments. Consul is a separate distributed key-value store and service mesh tool; Vault writes its encrypted data into Consul's KV store, and Consul's own Raft-based consensus handles replication and leader election for the Consul cluster, which Vault leverages for its own HA behavior (session-based locking to determine the active Vault node). Configuration looks like `storage "consul" { address = "127.0.0.1:8500" path = "vault/" }`. While still fully supported, Consul storage adds operational overhead (you must run and maintain a separate Consul cluster), so most new deployments favor Integrated Storage (Raft) unless Consul is already part of the infrastructure for service discovery purposes.

### Starting Vault Server
Starting Vault in production involves running `vault server -config=/path/to/config.hcl`, usually managed by a systemd unit so it restarts on failure and starts at boot. On first start with a fresh storage backend, the server will be **uninitialized** and **sealed** — it will respond to status checks but reject all secret operations. The systemd service typically runs as a dedicated `vault` user, has the `IPC_LOCK` capability (so memory isn't swapped, protecting secrets from being written to swap disk), and references the TLS certificates and storage paths defined in the config file. Logs are sent to stdout/stderr (captured by journald) by default, which can be redirected to other logging systems.

### Vault Initialization
**Initialization** is a one-time operation performed on a fresh Vault server using `vault operator init`. This process generates the **root key** (also called the master key) used to encrypt the encryption key that protects all data (the security barrier), and splits that root key into multiple **key shares** using Shamir's Secret Sharing (by default 5 shares, with a threshold of 3 required to reconstruct the key). It also generates an initial **root token** with full administrative privileges. The output of `vault operator init` — the unseal keys and root token — must be securely distributed and stored, since losing enough unseal key shares means the data in Vault becomes permanently inaccessible. Initialization happens only once per Vault cluster (subsequent nodes joining an HA cluster don't need to be separately initialized).

### Vault Unseal Process
Vault starts in a **sealed** state after every restart, meaning the in-memory encryption key needed to decrypt the storage backend's data is not available, and Vault cannot perform any operations on secrets. **Unsealing** is the process of reconstructing that encryption key by providing a threshold number of unseal key shares (e.g., 3 of 5) via `vault operator unseal`, run once per share. Each share is submitted separately (often by different trusted operators, enforcing separation of duties), and once the threshold is met, Vault combines the shares to reconstruct the root key, decrypts the encryption key, and transitions to the **unsealed** state, after which it can serve requests. This must be repeated every time a Vault server process restarts, unless auto-unseal is configured.

### Auto Unseal
**Auto Unseal** removes the need for operators to manually provide unseal key shares after every restart by delegating the unsealing operation to an external key management service (KMS), such as AWS KMS, Azure Key Vault, GCP Cloud KMS, or an HSM. With auto-unseal configured, Vault's root key is encrypted using a key held by the external KMS; on startup, Vault automatically calls out to that KMS to decrypt and retrieve the key needed to unseal itself — no human intervention required. This is essential for automated deployments (e.g., auto-scaling Vault nodes in Kubernetes or cloud auto-scaling groups) where manual unsealing would be impractical. Shamir's Secret Sharing is still used to generate **recovery keys** in auto-unseal setups, which serve a similar purpose for operations like generating a new root token.

---

## 3. Authentication Methods

### Token Authentication
The **Token auth method** is Vault's foundational authentication mechanism — every successful authentication via any method ultimately results in Vault issuing a token, which the client then presents on subsequent requests (typically via the `X-Vault-Token` header). Tokens have associated policies (determining permissions), a TTL (time-to-live), and metadata. The token auth method itself allows direct authentication using an existing token (`vault login <token>`) and is enabled by default at the `auth/token` path. While other auth methods are used for the initial identity verification (e.g., verifying a Kubernetes service account or an LDAP username/password), the result of that verification is always a Vault token that is then used for the actual API calls.

### Userpass Authentication
The **Userpass auth method** allows users to authenticate with a simple username and password stored directly in Vault. It's enabled with `vault auth enable userpass`, and users are created with `vault write auth/userpass/users/<username> password=<password> policies=<policy-names>`. While easy to set up and useful for testing, demos, or small teams without an existing identity provider, Userpass is generally discouraged for production human authentication at scale because it requires Vault to manage password storage and rotation directly rather than delegating to a centralized identity provider like LDAP or an OIDC-based SSO system.

### LDAP Authentication
The **LDAP auth method** allows users to authenticate against an existing LDAP directory (such as OpenLDAP or Microsoft Active Directory configured via LDAP) using their directory credentials. Vault is configured with the LDAP server URL, bind credentials, and search/group mapping configuration (`vault write auth/ldap/config url="ldaps://..." binddn="..." bindpass="..." userdn="..." groupdn="..."`). When a user logs in with `vault login -method=ldap username=<user>`, Vault binds to the LDAP server to verify the password and looks up the user's group memberships, mapping LDAP groups to Vault policies via `vault write auth/ldap/groups/<group> policies=<policy-names>`. This allows centralized identity management — when a user is removed from an LDAP group, their effective Vault permissions change automatically.

### Active Directory Authentication
Active Directory (AD) authentication in Vault is typically accomplished using the **LDAP auth method** pointed at an Active Directory domain controller, since AD exposes an LDAP interface. The configuration is the same as general LDAP auth but with AD-specific settings — for example, using `userdn` and `groupdn` that match AD's organizational unit structure, and often using `upndomain` to allow login with `user@domain.com` style usernames. Additionally, Vault offers a separate **AD Secrets Engine** (distinct from the auth method) that can manage and rotate Active Directory service account passwords dynamically — this is for *secrets management of AD accounts*, not for authenticating humans to Vault.

### GitHub Authentication
The **GitHub auth method** allows users to authenticate to Vault using a GitHub personal access token. Vault validates the token against the GitHub API to determine the user's identity and team memberships within a configured GitHub organization. Configuration involves setting the organization (`vault write auth/github/config organization=<org-name>`) and mapping GitHub teams to Vault policies (`vault write auth/github/map/teams/<team> value=<policy-names>`). This is convenient for organizations that already use GitHub for developer identity, allowing developers to log in to Vault with the same token they use for git operations, with access automatically tied to their GitHub team membership.

### AWS Authentication
The **AWS auth method** allows AWS entities (EC2 instances or IAM principals/roles) to authenticate to Vault without static credentials, using AWS's own identity primitives. It supports two methods: the **EC2 method**, where an EC2 instance presents its signed instance identity document to prove it's running in a specific AWS account/region/AMI, and the **IAM method**, where a caller signs a special `sts:GetCallerIdentity` request with their AWS credentials and Vault forwards that signed request to AWS STS to verify the caller's IAM identity (ARN). Vault maps the resulting AWS identity (account ID, IAM role ARN, EC2 instance tags, etc.) to Vault policies via configured roles (`vault write auth/aws/role/<role> auth_type=iam bound_iam_principal_arn=<arn> policies=<policies>`). This is widely used for workloads running on AWS, since the IAM role assigned to an EC2 instance or Lambda function becomes the basis for Vault access — no separate secret needs to be distributed.

### Azure Authentication
The **Azure auth method** enables Azure resources (VMs, VM Scale Sets, App Services, etc.) with **Managed Identities** to authenticate to Vault. The Azure resource obtains a signed JSON Web Token (JWT) from the Azure Instance Metadata Service, proving its identity (subscription, resource group, VM name, managed identity). Vault is configured with Azure tenant/client credentials to validate these tokens against Azure Active Directory, and roles map bound subscription IDs, resource groups, or VM names to Vault policies (`vault write auth/azure/role/<role> bound_subscription_ids=<id> bound_resource_groups=<rg> policies=<policies>`). This allows Azure-hosted applications to authenticate using their existing managed identity rather than a separate Vault credential.

### GCP Authentication
The **GCP auth method** allows Google Cloud entities — either **GCE instances** (using their instance identity metadata/JWT) or **IAM service accounts** (using a signed JWT obtained via the IAM API) — to authenticate to Vault. Vault validates the signed JWT against Google's public certificates and the GCP IAM API, then matches the service account email, project, or instance metadata against configured roles (`vault write auth/gcp/role/<role> type=iam bound_service_accounts=<sa-email> policies=<policies>`). This lets workloads running on Google Cloud use their assigned service account identity to obtain Vault tokens without managing separate static credentials.

### Kubernetes Authentication
The **Kubernetes auth method** is one of the most widely used auth methods for cloud-native deployments. A pod running in a Kubernetes cluster has a **service account token** automatically mounted into its filesystem (typically at `/var/run/secrets/kubernetes.io/serviceaccount/token`). The pod presents this JWT token to Vault's `auth/kubernetes/login` endpoint along with a role name. Vault, which is configured with the Kubernetes API server address and a token reviewer JWT, calls the Kubernetes TokenReview API to validate the service account token and confirm it belongs to the expected namespace and service account. Roles map bound service accounts/namespaces to Vault policies (`vault write auth/kubernetes/role/<role> bound_service_account_names=<sa> bound_service_account_namespaces=<ns> policies=<policies>`). This allows pods to authenticate to Vault with zero static secrets — their identity is their Kubernetes service account.

### AppRole Authentication
**AppRole** is an auth method designed specifically for machine-to-machine and application authentication, where there's no human or cloud-provider identity to leverage. An AppRole consists of a **Role ID** (similar to a username, identifying which role/policy set to use — not secret) and a **Secret ID** (similar to a password — must be kept confidential). Applications authenticate by presenting both the Role ID and a Secret ID to `auth/approle/login`, receiving a Vault token in return. Secret IDs can be configured to be single-use, time-limited, and tied to specific CIDR blocks for extra security, and can be generated on-demand and distributed via a separate secure channel (a common pattern is having a trusted orchestration system fetch a Secret ID and pass it to the application at startup). AppRole is the de-facto standard for CI/CD pipelines and applications running outside of a cloud provider's native identity system.

### OIDC Authentication
The **OIDC auth method** integrates Vault with OpenID Connect identity providers (Okta, Azure AD, Google, Auth0, etc.), enabling browser-based single sign-on (SSO) login. Vault is configured with the OIDC provider's discovery URL, client ID, and client secret. When a user runs `vault login -method=oidc`, Vault opens a browser window directing the user to authenticate with the identity provider; upon success, the provider redirects back to Vault with an authorization code, which Vault exchanges for tokens and uses to determine the user's identity and group claims, mapping them to Vault policies. This provides a familiar SSO experience for human users and centralizes identity lifecycle management (e.g., disabling a user in the IdP immediately revokes their ability to log in to Vault).

### JWT Authentication
The **JWT auth method** is a more generic version of OIDC — it allows authentication using any signed JSON Web Token (JWT), validated either against a static public key/JWKS endpoint or an OIDC provider's JWKS, without necessarily performing the full OIDC browser login flow. It's commonly used for service-to-service authentication where a JWT is issued by some external system (e.g., a CI/CD platform like GitHub Actions OIDC tokens, GitLab CI ID tokens) and Vault validates the token's signature, issuer, audience, and claims against configured **bound** values, mapping the claims to policies. This makes it possible for ephemeral CI/CD jobs to authenticate to Vault using a short-lived, platform-issued JWT instead of a long-lived static credential.

## 4. Vault Policies & Authorization

### ACL Policies
Access Control List (ACL) policies are the primary mechanism for authorization in Vault. A policy is a document (written in HCL or JSON) that specifies which API paths an identity is permitted to access and what operations (capabilities) are allowed on those paths. Policies are attached to tokens (directly or via auth method role configuration), and a token's effective permissions are the union of all attached policies. By default, Vault denies all access — a path must be explicitly granted via a policy capability for any operation to succeed. Policies are managed with `vault policy write <name> <file.hcl>`, `vault policy read <name>`, and `vault policy list`.

### Policy Syntax (HCL)
Policies are written as a series of `path` blocks, each specifying a path pattern (which can include wildcards `*` and `+`) and the `capabilities` allowed on that path. For example:
```hcl
path "secret/data/myapp/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/data/myapp/config" {
  capabilities = ["read"]
}
```
Wildcards: `*` matches any number of characters at the end of a path segment (or the rest of the path), while `+` matches exactly one path segment. Policies can also specify `denied_parameters` or `allowed_parameters` to restrict which values can be written for specific keys, and `min_wrapping_ttl`/`max_wrapping_ttl` for response wrapping constraints. When multiple policies apply to overlapping paths, the most specific match and the broadest capability generally take precedence, but an explicit `deny` capability on a path always overrides any `allow`.

### Capabilities
Capabilities define the specific operations permitted on a path, analogous to HTTP verbs mapped onto Vault's API:

#### create
Allows creating a new secret or resource at a path (HTTP POST/PUT) where one does not currently exist. For KV v2, this generally requires `create` for initial writes (and `update` for subsequent writes).

#### read
Allows retrieving (HTTP GET) data from a path — for example, reading a secret's value, reading a role's configuration, or generating dynamic credentials (since many dynamic-secret generation endpoints respond to GET/read).

#### update
Allows modifying an existing resource at a path (HTTP POST/PUT on an existing entry). For many secrets engine configuration paths, `update` is required to change settings.

#### delete
Allows removing a secret or resource at a path (HTTP DELETE) — for example, deleting a KV secret version or removing a configured role.

#### list
Allows enumerating the keys that exist under a path (HTTP LIST, which Vault maps to a GET with a `?list=true` parameter). This is required for the `vault kv list` command and for browsing secrets in the UI; without it, a user might be able to read a specific known path but not discover what other paths exist.

#### sudo
A special elevated capability required for certain sensitive root-protected operations regardless of other capabilities granted — for example, modifying the audit log configuration, generating a root token, or accessing certain `sys/` endpoints. Even a token with `update` on a path may be denied if `sudo` is also required and not granted.

### RBAC Concepts
Role-Based Access Control (RBAC) in Vault is implemented through the combination of auth method roles and ACL policies: an auth method (e.g., Kubernetes, LDAP, AppRole) maps an external identity (a service account, an LDAP group, an AppRole) to one or more named policies, and those policies define the actual permissions. This indirection means access can be managed at the "role" level — e.g., "the `payments-service` Kubernetes service account gets the `payments-app` policy" — without needing to hardcode permissions per individual token. Identity groups (see Identity Management) add another layer, allowing policies to be assigned to groups of entities rather than individual auth method roles.

### Least Privilege Access
The principle of least privilege means every identity (human or machine) should be granted only the minimum set of permissions necessary to perform its function, and nothing more. In Vault, this translates to writing narrowly-scoped policies (e.g., a service should only have `read` on the exact secret path it needs, not `*` access to an entire mount), preferring dynamic secrets over broad static secret access, using short TTLs so even leaked credentials expire quickly, and avoiding the use of root tokens for routine operations (root tokens should be generated only when needed, used immediately, and revoked afterward). Regularly auditing policies and token usage helps identify and remove unnecessary permissions ("policy drift") over time.

### Policy Management
Operationally, policies should be treated as code: stored in version control, reviewed via pull requests, and applied through automation (e.g., Terraform's `vault_policy` resource or a CI/CD pipeline running `vault policy write`). Vault also supports **templated policies**, where policy paths can include placeholders like `{{identity.entity.id}}` or `{{identity.entity.aliases.<mount accessor>.name}}`, allowing a single policy to dynamically scope access based on the authenticated identity (e.g., granting each user access only to `secret/data/users/{{identity.entity.name}}/*`). This avoids needing to write a near-duplicate policy for every individual user or service.

---

## 5. Tokens

### Root Token
The **root token** is a special, all-powerful token with the built-in `root` policy, which bypasses all ACL checks entirely — it can perform any operation on any path. The initial root token is generated during `vault operator init`. Because of its unrestricted power, root tokens should be used sparingly: typically only for initial setup (enabling auth methods, secrets engines, writing the first policies), and should be revoked immediately afterward. Best practice is to generate a new, short-lived root token only when absolutely necessary (using `vault operator generate-root`, which requires unseal key holders to authorize), perform the required action, and revoke it immediately.

### Service Tokens
**Service tokens** are the standard, full-featured token type — they support renewal, can be periodic, can create child tokens, and have complete lease and TTL tracking stored in Vault's storage backend. Most tokens issued by auth methods (e.g., when a user logs in via LDAP or a pod authenticates via Kubernetes auth) are service tokens. They're called "service" tokens to distinguish them from the more lightweight "batch" tokens. Service tokens carry more storage overhead in Vault because their state must be persisted and replicated.

### Batch Tokens
**Batch tokens** are a lightweight, high-performance alternative to service tokens, designed for high-volume, short-lived use cases (e.g., a serverless function that needs a token for a single brief operation). Batch tokens are encoded and encrypted entirely within the token string itself (not stored server-side), making them extremely cheap to issue at scale — but this means they **cannot be renewed** (they're created with a fixed TTL and simply expire), **cannot create child tokens**, and any dynamic secrets/leases generated using a batch token are tied to the batch token's lifetime and revoked together with it rather than independently. They're ideal for ephemeral workloads where the overhead of service token storage isn't justified.

### Token TTL
Time-To-Live (TTL) defines how long a token remains valid before it expires. Every token has a TTL, which can be set explicitly at creation time or inherited from the auth method's configured default (`default_lease_ttl`) and capped by a `max_ttl`. When a token's TTL expires without renewal, Vault automatically revokes it and any leases (dynamic secrets) created using it. Short TTLs reduce the window of exposure if a token is compromised but require more frequent renewal; administrators balance security against operational overhead when setting TTL defaults and maximums.

### Renewable Tokens
A **renewable** token can have its TTL extended before it expires, via `vault token renew <token>`, up to the token's `max_ttl` (the absolute upper bound, after which it cannot be renewed further regardless of renewal attempts). Most service tokens are renewable by default. Long-running applications typically run a renewal loop (often handled automatically by **Vault Agent**) that periodically renews their token well before expiration, ensuring continuous access without needing to fully re-authenticate. Batch tokens are never renewable.

### Orphan Tokens
By default, tokens are created as children of the token that created them, forming a tree — if the parent token is revoked, all its child tokens are also revoked (cascading revocation). An **orphan token** has no parent in this hierarchy; it exists independently, and revoking the token that created it does *not* affect the orphan. Orphan tokens are useful for long-lived service identities that shouldn't be tied to the lifecycle of whatever short-lived token initially created them. They're created with the `orphan` flag (`vault token create -orphan`), and creating orphan tokens generally requires the `sudo` capability on the relevant token-creation path.

### Token Revocation
Revoking a token immediately invalidates it and — critically — also revokes all leases (dynamic secrets, dynamic database credentials, etc.) that were created using that token, and cascades to revoke any child tokens (unless they're orphans). This is done via `vault token revoke <token>` or `vault token revoke -accessor <accessor>` (using the token's accessor instead of the token value itself, useful when an administrator needs to revoke a token without knowing its actual secret value). Revocation is the primary "kill switch" for compromised credentials — revoking the token that issued a set of dynamic database credentials will cause Vault to immediately delete those database users.

### Token Lookup
**Token lookup** allows inspecting metadata about a token — its policies, TTL, creation time, number of uses remaining, whether it's an orphan, its accessor, and associated metadata — without exposing the actual secret value of other tokens unnecessarily. `vault token lookup` (with no arguments) inspects the caller's own token, while `vault token lookup -accessor <accessor>` allows an administrator with appropriate permissions to inspect any token's metadata using only its accessor (a non-secret identifier), which is important for auditing and troubleshooting without needing to handle other users' actual token secrets.

### Token Roles
**Token roles** allow administrators to predefine constraints and defaults for tokens created under a given role, such as allowed/disallowed policies, a fixed set of policies that are always included, TTL and max TTL bounds, whether tokens created under the role are orphans, whether they're renewable, and the token type (service or batch). Token roles are configured at `auth/token/roles/<role-name>` and are referenced when creating a token (`vault token create -role=<role-name>`). This is useful for standardizing how certain categories of tokens are issued — for example, ensuring all tokens created for a particular automation system always get a specific policy and never exceed a 1-hour TTL, regardless of what the requester asks for.

---

## 6. Secrets Engines

### KV Secrets Engine
The **Key-Value (KV) secrets engine** is the simplest and most commonly used secrets engine — it stores arbitrary key-value pairs (static secrets) at user-defined paths, similar to a secure, versioned filesystem. It's enabled with `vault secrets enable -path=secret kv-v2` (or `kv` for version 1) and accessed via `vault kv put/get/delete/list secret/<path>`. Typical uses include storing database connection strings, API keys for third-party services, TLS private keys, and application configuration values that don't have a dedicated dynamic secrets engine.

### KV Version 1
KV v1 is the original, simpler version of the KV secrets engine. It stores only the current value of a secret at each path — writing a new value at a path completely overwrites the previous value with no history retained. It has lower storage overhead and simpler API semantics (a write is just a write), making it suitable for use cases where versioning isn't needed and storage efficiency matters more (e.g., very high-volume secret writes). However, the lack of history means accidental overwrites or deletions are unrecoverable.

### KV Version 2
KV v2 adds **versioning** on top of the basic key-value model: every write creates a new version of the secret rather than overwriting it, and previous versions remain retrievable (up to a configurable maximum number of versions per path). KV v2 also supports **soft deletes** (marking a version as deleted but recoverable) and **destroy** (permanently and irrecoverably removing specific versions). The API paths differ slightly from v1 — data operations go through `secret/data/<path>` while metadata operations (version info, delete/undelete/destroy) go through `secret/metadata/<path>`. KV v2 is the recommended default for new deployments due to its auditability and recoverability.

### Secret Versioning
Versioning (a KV v2 feature) means each write to a given path is stored as an incrementing version number, and any previous version can be retrieved with `vault kv get -version=<n> <path>`. The number of versions retained per key is configurable (`max_versions`, default 10), and once that limit is exceeded, the oldest versions are permanently removed. Versioning provides an audit trail of how a secret has changed over time and allows rollback to a previous value if a bad update is pushed — for example, reverting an API key change that broke an integration.

### Secret Rotation
Secret rotation refers to periodically changing a secret's value to limit the window during which a compromised credential remains useful. For static secrets (KV), rotation is typically a manual or externally-automated process — something (a script, CI job, or the relevant cloud provider's own rotation feature) generates a new value and writes it to Vault. For dynamic secrets engines (Database, AWS, etc.), rotation is largely automatic: Vault generates a brand-new credential for each lease and can also be configured to rotate the **root credentials** the secrets engine itself uses to connect to the backend system, ensuring even Vault's own administrative credentials don't remain static indefinitely.

### Dynamic Secrets
Dynamic secrets are credentials generated by Vault on-demand, unique to each request, and tied to a **lease** with a TTL. When the lease expires (or is explicitly revoked), Vault automatically performs cleanup — for a database, this means dropping the dynamically-created user; for AWS, deleting the temporary IAM credentials. Because each requester gets a unique credential, compromise of one credential doesn't affect others, and because credentials are short-lived, an attacker who obtains one has a limited window to use it. Dynamic secrets are supported by engines including Database, AWS, Azure, GCP, and SSH.

### Database Secrets
The **Database secrets engine** generates dynamic credentials for relational and NoSQL databases. An administrator configures a connection to the database (with Vault-managed admin credentials) and defines **roles** that specify the SQL/commands used to create a new user with specific privileges. When an application requests credentials from a role, Vault connects to the database using its admin credentials, runs the creation statement to create a brand-new, randomly-named/passworded user, and returns those credentials with a lease. When the lease expires, Vault runs a corresponding revocation statement to drop that user. Supported databases include PostgreSQL, MySQL/MariaDB, MSSQL, Oracle, MongoDB, Cassandra, and others via plugins.

### AWS Secrets
The **AWS secrets engine** generates dynamic AWS IAM credentials (access key/secret key pairs) or STS-based temporary credentials (using `AssumeRole` or federation tokens). Administrators configure Vault with root AWS credentials capable of creating IAM users/roles or assuming roles, then define roles in Vault specifying either an IAM policy document (for creating dynamic IAM users) or an ARN to assume (for STS credentials). Applications request credentials and receive temporary AWS access keys with a lease; on expiration/revocation, Vault deletes the IAM user (if that mode was used) or simply lets the STS credentials expire naturally.

### Azure Secrets
The **Azure secrets engine** generates dynamic Azure Active Directory service principals with specified role assignments, on-demand. Vault is configured with credentials for an Azure AD application that has sufficient permissions to create service principals and assign roles within target subscriptions. Roles in Vault define the Azure roles/scopes to assign to the generated service principal. When requested, Vault creates a new service principal with a randomly generated password and the configured role assignments; on lease expiration, the service principal is deleted.

### GCP Secrets
The **GCP secrets engine** can generate either OAuth2 access tokens or service account keys for Google Cloud, scoped to specific IAM roles on specific resources. Vault is configured with a GCP service account that has permission to manage IAM bindings, and roles define the target service account(s) and the type of credential to generate (a short-lived OAuth token via impersonation, or a downloadable service account key file). This allows applications to obtain temporary GCP credentials without Vault needing to store long-lived service account keys for every consumer.

### SSH Secrets
The **SSH secrets engine** provides secure, time-limited SSH access in several modes: **OTP (one-time-password) mode**, where Vault generates a one-time password that's installed on the target host (via a helper agent) and verified at login time; **CA (certificate authority) mode**, where Vault signs short-lived SSH certificates for client public keys, and target hosts trust Vault's CA public key — this is the most scalable and recommended mode since hosts don't need per-credential configuration; and **Dynamic Key mode** (largely deprecated), where Vault manages and rotates static SSH key pairs on target hosts. CA mode is widely favored because it eliminates the need to distribute or rotate SSH keys on hosts entirely — access is controlled purely by whether Vault will sign a certificate for a given user/host/TTL.

### PKI Secrets Engine
The **PKI secrets engine** turns Vault into a Certificate Authority (CA), capable of dynamically issuing TLS/SSL certificates on demand. Administrators configure a root and/or intermediate CA within Vault (or import an externally-signed intermediate), define **roles** that constrain what certificates can be requested (allowed domains, max TTL, key types, whether subdomains/wildcards are permitted), and applications request certificates via `vault write pki/issue/<role> common_name=<domain>`. Vault generates a new key pair (or accepts a CSR), signs the certificate using the configured CA key, and returns the certificate, private key, and CA chain — all with a defined TTL. This enables short-lived certificates issued automatically, dramatically reducing reliance on long-lived certs that are painful to rotate.

#### Certificates
In the PKI context, certificates are the signed public-key documents issued by Vault's CA, used by services for TLS (encrypting traffic) and mTLS (mutual authentication). Each certificate includes a Common Name (and/or Subject Alternative Names), validity period, public key, and the CA's digital signature. Vault tracks issued certificates and their serial numbers, enabling revocation tracking.

#### CA Management
Vault's PKI engine can generate a **self-signed root CA** (`vault write pki/root/generate/internal`) for internal-only trust hierarchies, or generate an **intermediate CA** whose CSR is signed by an external/offline root CA (`vault write pki/intermediate/generate/internal`, then signed externally and imported back with `vault write pki/intermediate/set-signed`). Best practice is to keep root CAs offline/highly restricted and use Vault-managed intermediate CAs for day-to-day certificate issuance, limiting the blast radius if the intermediate is ever compromised (it can be revoked and reissued without invalidating trust in the root).

#### Certificate Rotation
Because Vault can issue certificates with arbitrarily short TTLs (e.g., hours rather than years), "rotation" effectively becomes continuous reissuance rather than a periodic manual task. Applications (often via Vault Agent templates) periodically request a fresh certificate before the current one expires and reload it into the service. This dramatically reduces the operational risk associated with forgotten, manually-tracked certificate expirations.

### Transit Secrets Engine
The **Transit secrets engine** provides "encryption as a service" — applications send plaintext to Vault and receive ciphertext (or vice versa) without ever handling the encryption keys themselves. Vault manages named **encryption keys** internally; applications call `vault write transit/encrypt/<key-name> plaintext=<base64-data>` and `vault write transit/decrypt/<key-name> ciphertext=<ciphertext>`. This is useful for applications that need strong encryption but shouldn't (for compliance or operational reasons) have direct access to raw key material — key management, rotation, and access control are all centralized in Vault.

#### Encryption as a Service
This describes the overall pattern enabled by Transit: cryptographic operations (encrypt, decrypt, sign, verify, HMAC, hash) are performed by Vault on behalf of clients, with the actual keys never leaving Vault. This separates "who can use a key to encrypt/decrypt data" (controlled by Vault policy) from "who has the key material" (nobody outside Vault), simplifying compliance (e.g., key custody requirements) and centralizing key lifecycle management.

#### Encrypt Data
`vault write transit/encrypt/<key-name> plaintext=<base64-encoded-data>` returns a ciphertext string prefixed with a version identifier (e.g., `vault:v1:...`). The ciphertext can be safely stored by the application (e.g., in a database column) since it's useless without access to Vault's Transit engine and appropriate policy permissions to decrypt it.

#### Decrypt Data
`vault write transit/decrypt/<key-name> ciphertext=<ciphertext>` returns the original base64-encoded plaintext, provided the caller's token has `update` capability on the decrypt path for that key. Because the ciphertext embeds the key version used, Vault can decrypt data even after the key has been rotated to a newer version (as long as the old key version hasn't been explicitly disabled).

#### Rewrap
`vault write transit/rewrap/<key-name> ciphertext=<old-ciphertext>` re-encrypts data that was encrypted under an older key version using the current (latest) key version, **without exposing the plaintext** to the caller — Vault decrypts internally with the old key and re-encrypts with the new key in one operation. This is the recommended way to "upgrade" stored ciphertexts after a key rotation, ensuring old key versions can eventually be retired.

#### Key Rotation
`vault write -f transit/keys/<key-name>/rotate` generates a new version of the named key while retaining previous versions (up to a configurable `min_decryption_version`). New encrypt operations automatically use the latest version, while decrypt operations can still use older versions for existing ciphertext (unless those versions are explicitly disabled via `min_decryption_version`). This allows seamless key rotation without needing to immediately re-encrypt all existing data (though `rewrap` can be used to migrate data to the new version over time).

## 7. Vault Security Concepts

### Security Barrier
The security barrier is the cryptographic layer that sits between Vault's core logic and its storage backend. Every piece of data Vault writes to storage — secrets, configuration, policies, tokens, leases — passes through this barrier and is encrypted before being persisted, and decrypted when read back. This means the storage backend (Raft, Consul, file, etc.) never holds plaintext data; even if an attacker gains direct access to the storage backend's files or database, the data is useless without the encryption key that only exists in Vault's memory when unsealed. The barrier is implemented using AES-256-GCM with the **encryption key**, which itself is protected by the **root key** generated during initialization.

### Seal & Unseal
"Sealed" is Vault's default state on startup — the in-memory encryption key needed to decrypt the barrier is not present, so Vault cannot read or write any secret data, though it can still respond to a small set of unauthenticated status endpoints. "Unsealing" reconstructs that encryption key, transitioning Vault to a fully operational state. Sealing can also be triggered manually (`vault operator seal`) as an emergency response — for example, if an operator suspects the server's memory has been compromised, sealing immediately wipes the in-memory key, rendering all data inaccessible until a proper unseal is performed again.

### Shamir Secret Sharing
Shamir's Secret Sharing is the cryptographic algorithm used to split Vault's root key into multiple **key shares** (default 5) such that a configurable **threshold** number of shares (default 3) are required to reconstruct the original key — but any number of shares below the threshold reveals nothing about the key. This is the mechanism behind the manual unseal process: distributing shares to different trusted individuals enforces that no single person can unseal Vault alone (separation of duties), while still tolerating the loss of some shares (up to `shares - threshold`) without permanently losing access. When auto-unseal is used, Shamir shares are instead used to generate **recovery keys**, serving a similar purpose for specific recovery operations.

### Encryption at Rest
All data persisted by Vault to its storage backend is encrypted at rest via the security barrier, using AES-256-GCM. This applies uniformly regardless of which storage backend is used — Raft, Consul, file, etc. — since encryption happens before the data ever reaches the storage layer. This means operators don't need to separately configure disk encryption for Vault's data to be protected from someone who gains filesystem-level access to the storage backend (though disk encryption is still good general practice defense-in-depth).

### Encryption in Transit
All communication with Vault — between clients and the API, between Vault cluster nodes, and between Vault and replicated clusters — should be protected with TLS. Vault's `listener` configuration specifies TLS certificate and key files for the API listener, and the `cluster_addr` communication between HA nodes is also TLS-protected. Running Vault without TLS (as in `-dev` mode) means tokens, secrets, and unseal keys could be intercepted on the network, so production deployments must always enable TLS on all listeners.

### TLS Configuration
TLS is configured within the `listener "tcp" { ... }` block of Vault's configuration file, specifying `tls_cert_file`, `tls_key_file`, and optionally `tls_client_ca_file` (for mutual TLS), `tls_min_version`, and cipher suite restrictions. Certificates can come from an internal CA, a public CA, or — fittingly — be issued by Vault's own PKI secrets engine (with appropriate bootstrapping). Clients (CLI, applications) need to trust the CA that issued Vault's server certificate, either via the system trust store or by specifying `VAULT_CACERT`.

### mTLS
Mutual TLS (mTLS) extends standard TLS so that both the client and server present certificates, allowing each side to verify the other's identity. Vault supports mTLS as both a server feature (clients must present a certificate Vault trusts) and as part of the **TLS Certificate auth method**, where a client's certificate itself serves as its authentication credential — Vault maps the certificate's CA and/or specific certificate fingerprints to policies. mTLS is common in zero-trust architectures and service-mesh environments where every connection, not just Vault's, requires mutual authentication.

### Audit Logging
Audit devices record every request to and response from Vault, providing a complete, tamper-evident trail for compliance and security investigations. Vault supports multiple audit device types (file, syslog, socket) that can be enabled simultaneously; if **all** enabled audit devices fail to write (e.g., disk full), Vault will **block all requests** rather than operate without an audit trail — a deliberate fail-closed design. Sensitive values (tokens, secret data) in audit logs are HMAC'd using a key derived from the audit device's configuration, so logs show that a particular secret *was* accessed without revealing its actual value, while still allowing correlation (the same secret always produces the same HMAC).

### Secure Secret Rotation
Beyond individual secret rotation (covered in section 6), "secure secret rotation" as a concept emphasizes designing rotation so it never creates a window of broken access — for example, dynamic database credentials with overlapping leases ensure a new credential is available before the old one expires, and Transit key rotation retains old key versions for decryption so existing encrypted data remains readable. Root credential rotation for secrets engines (Database, AWS, etc.) should similarly be automated and tested so Vault's own ability to manage the backend isn't accidentally broken by a rotation that locks Vault out.

### Root Key Rotation
The **root key** (generated at initialization, used to protect the encryption key) can itself be rotated using `vault operator rotate`, which generates a new encryption key (re-keying the barrier) without requiring re-initialization. Separately, `vault operator generate-root` can be used to rotate/regenerate the **root token** — this process requires unseal key holders to provide their shares to authorize the generation of a new root token via a one-time-password (OTP) mechanism, ensuring root token generation also respects the separation-of-duties model established by Shamir sharing.

---

## 8. Identity Management

### Entities
An **entity** in Vault represents a single human or service, independent of how that identity authenticates. A user might authenticate via LDAP from their laptop and via AppRole from a CI pipeline — Vault can map both of those distinct authentication events (aliases) to a single entity, representing "this is the same person/service." Policies, MFA requirements, and metadata can be attached directly to an entity, applying consistently regardless of which auth method was used to log in. Entities are created automatically on first login (if entity management is enabled) or can be created/managed explicitly via `vault write identity/entity`.

### Groups
**Groups** allow policies and metadata to be assigned to collections of entities, similar to RBAC groups in other systems. Vault supports two types of groups: **internal groups**, where membership is explicitly managed within Vault by adding entity IDs, and **external groups**, where membership is automatically derived from group information provided by an external auth method (e.g., an LDAP group or an OIDC group claim) via group aliases. Policies attached to a group apply to all member entities, simplifying permission management — adding a user to an external LDAP group automatically grants them the corresponding Vault group's policies.

### Aliases
An **alias** is the link between an entity and a specific identity within a specific auth method (technically, an auth method "mount"). For example, an entity representing "Alice" might have one alias for her LDAP username `alice` under the LDAP auth mount, and another alias for her GitHub username `alice-dev` under the GitHub auth mount. When Alice logs in via either method, Vault recognizes the alias and associates the resulting token with her single underlying entity, ensuring entity-level policies and metadata apply consistently regardless of login method.

### Identity Store
The identity store is Vault's internal database of entities, groups, and aliases, exposed via the `identity/` API path. It's managed both implicitly (entities/aliases are often auto-created on login) and explicitly (administrators can pre-create entities, assign metadata, and define group memberships ahead of time). The identity store underpins features like templated policies (referencing `{{identity.entity.*}}`), Identity-based MFA enforcement, and the mapping of external group memberships to Vault groups.

### External Groups
External groups are Vault groups whose membership is **not** managed directly in Vault but is instead synchronized from an external system via **group aliases**. For example, an external group can have a group alias pointing to the `engineering` group in an LDAP directory; whenever a user who is a member of the LDAP `engineering` group logs in, Vault automatically considers their entity a member of the corresponding external group, and any policies attached to that external group apply to them — without an administrator ever manually managing group membership inside Vault.

### Group Policies
Policies can be attached directly to a group (`vault write identity/group/name/<group-name> policies=<policy-names>`), and any entity that is a member of that group (whether through internal membership or via an external group alias) inherits those policies in addition to any policies attached directly to their entity or granted by their auth method role. This layered model — auth method policies + entity policies + group policies — allows flexible, centrally-managed access control that mirrors how organizations actually structure permissions (by team/role) rather than per individual credential.

---

## 9. Database Secrets Engine

### MySQL Integration
To integrate MySQL/MariaDB, an administrator enables the database secrets engine, then writes a connection configuration specifying the plugin (`mysql-database-plugin`), connection URL (with a templated username/password for the admin account Vault uses), and allowed roles. A role defines the `creation_statements` — SQL executed to create a new user, typically something like `CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}'; GRANT SELECT ON app_db.* TO '{{name}}'@'%';` — along with `default_ttl` and `max_ttl`. Vault substitutes `{{name}}` and `{{password}}` with a generated random username/password each time credentials are requested, and `revocation_statements` (often `DROP USER` or `REVOKE`) clean up when the lease ends.

### PostgreSQL Integration
PostgreSQL integration follows the same pattern using the `postgresql-database-plugin`. Creation statements typically use `CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";`. PostgreSQL's `VALID UNTIL` clause provides a database-enforced expiration as a defense-in-depth measure even if Vault's revocation somehow fails to run. Vault's admin connection user needs sufficient privileges (e.g., `CREATEROLE`) to create and drop these dynamic users.

### Oracle Integration
Oracle integration uses the `oracle-database-plugin` (often distributed as an external plugin requiring separate registration). Creation statements use Oracle SQL syntax (`CREATE USER {{name}} IDENTIFIED BY "{{password}}"; GRANT CONNECT TO {{name}};`). Oracle environments often have stricter username length limits and licensing considerations around the number of active sessions/users, so Vault role TTLs and `max_ttl` settings need to account for how quickly dynamically-created users accumulate before being revoked.

### MSSQL Integration
Microsoft SQL Server integration uses the `mssql-database-plugin`, with creation statements like `CREATE LOGIN [{{name}}] WITH PASSWORD = '{{password}}'; CREATE USER [{{name}}] FOR LOGIN [{{name}}]; GRANT SELECT TO [{{name}}];` (often within a `USE <database>` context). As with other engines, the Vault-managed admin login needs sufficient server-level privileges to create logins/users and assign permissions, and `revocation_statements` drop both the login and user on lease expiration.

### Dynamic Database Credentials
Across all supported databases, the core workflow is the same: a client calls `vault read database/creds/<role-name>`, Vault connects using its stored admin credentials, executes the role's creation statement with a freshly-generated random username and password, and returns those credentials along with a `lease_id` and `lease_duration`. The application uses these credentials directly to connect to the database. This means every application instance (or every connection, depending on how often credentials are requested) can have its own unique database user, dramatically improving traceability (database audit logs show exactly which Vault-issued credential performed which action) compared to all instances sharing one static service account.

### Credential Leasing
Every dynamic secret Vault generates is associated with a **lease** — a record of the secret's TTL and the information needed to revoke it. Leases are tracked by Vault's expiration manager, which automatically revokes secrets when their lease expires by invoking the issuing secrets engine's revocation logic. Leases can be renewed (`vault lease renew <lease_id>`) up to the role's `max_ttl`, or revoked early (`vault lease revoke <lease_id>`) to immediately trigger cleanup — for the database engine, this means immediately dropping the dynamically-created user, even if its natural TTL hasn't elapsed.

### Revocation
Revocation is the cleanup process triggered when a lease expires or is explicitly revoked. For the database secrets engine, this runs the role's `revocation_statements` (commonly `DROP USER` / `DROP ROLE` / `DROP LOGIN` depending on the database) against the target database using Vault's admin connection. If revocation fails (e.g., the database is temporarily unreachable), Vault retries with backoff and tracks the lease as still pending revocation, ensuring orphaned dynamic users don't accumulate silently — though prolonged outages can lead to a backlog that administrators may need to address manually.

---

## 10. PKI Secrets Engine (Detailed)

### Root CA
A root CA is the top of a certificate trust hierarchy — it's typically self-signed. Within Vault's PKI engine, you can generate an internal root CA (`vault write pki/root/generate/internal common_name="Example Root CA" ttl=87600h`), which creates a private key that never leaves Vault and a self-signed root certificate. Because compromise of a root CA's key would undermine trust in every certificate it (directly or transitively) signed, best practice is to use this root only to sign one or more intermediate CAs and then keep the root mount sealed off / unmounted ("offline") for day-to-day operations.

### Intermediate CA
An intermediate CA sits between the root and the certificates issued to end services. Vault generates an intermediate CSR (`vault write pki_int/intermediate/generate/internal common_name="Example Intermediate CA"`), which is then signed by the root CA (either Vault's own root mount, via `vault write pki/root/sign-intermediate`, or an external/offline root) producing a signed intermediate certificate that's imported back into the intermediate mount (`vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem`). All day-to-day certificate issuance happens from this intermediate, so if it's ever compromised, only the intermediate (and certs it issued) need to be revoked/reissued — the root remains trusted.

### Certificate Issuance
End-entity certificates are issued via configured **roles**, which constrain what can be requested — allowed domains (`allowed_domains`), whether subdomains or wildcards are permitted (`allow_subdomains`, `allow_wildcard_certificates`), key type/size, and maximum TTL. Issuance happens via `vault write pki_int/issue/<role> common_name="service.example.com" ttl="24h"`, which returns a freshly generated private key, signed certificate, and the CA chain — all in one response. Alternatively, `pki_int/sign/<role>` accepts a CSR from the client (so the private key never touches Vault) and returns just the signed certificate.

### Certificate Revocation
If a certificate's private key is compromised or it needs to be invalidated early, `vault write pki_int/revoke serial_number=<serial>` marks it as revoked. Revoked certificate serial numbers are added to the CA's **Certificate Revocation List (CRL)**. Note that because Vault-issued certs often have short TTLs by design, explicit revocation is less critical than in traditional long-lived-certificate PKI — many certificates will simply expire naturally within hours or days.

### CRL
The Certificate Revocation List is a signed list of certificate serial numbers that have been revoked before their natural expiration, published by Vault's PKI engine at a predictable URL (configurable via `pki_int/config/urls`) and automatically embedded into issued certificates' CDP (CRL Distribution Point) extension. Clients validating a certificate can fetch this CRL to check whether it's been revoked. Vault also supports OCSP (Online Certificate Status Protocol) as an alternative/complementary revocation-checking mechanism.

### PKI Roles
A PKI role is a named configuration object that defines the policy constraints for certificate issuance under that role — domains allowed, TTL limits, key algorithms (RSA/EC), key usage and extended key usage flags, whether the role can issue CA certificates itself, and IP/SAN restrictions. Roles let administrators offer different "tiers" of certificate issuance — e.g., a `short-lived-internal` role permitting only `*.internal.example.com` with a 24-hour max TTL, versus a more restricted role for externally-facing services requiring additional approval steps outside Vault.

### Auto-Rotation
"Auto-rotation" for PKI generally refers to application-side automation (often via Vault Agent templates) that periodically requests a new certificate from Vault well before the current one expires, writes it to disk, and signals the application (e.g., via a reload hook) to pick up the new certificate — achieving continuous rotation without manual intervention or downtime. Vault itself doesn't "push" renewed certificates; the pattern is pull-based, driven by the consuming application or its sidecar agent.

---

## 11. Transit Secrets Engine (Detailed)

### Data Encryption
Beyond the basic `transit/encrypt` operation covered earlier, Transit supports **convergent encryption** (the same plaintext + context always produces the same ciphertext, useful for searchable encrypted fields, though it leaks equality information) and **batch operations** (encrypting/decrypting many items in a single API call for efficiency). Encryption can also use a **key derivation** context, allowing a single named key to effectively act as many derived keys (one per context value) without managing separate key objects for each.

### Data Decryption
Decryption requires the caller to have `update` capability on `transit/decrypt/<key-name>` and to supply the same `context` value (if key derivation was used during encryption). Vault identifies the correct key version from the ciphertext's embedded version prefix, so decryption works correctly even for ciphertext encrypted under older key versions, as long as `min_decryption_version` hasn't been raised past that version.

### Key Management
Transit keys are managed entirely within Vault — created with `vault write -f transit/keys/<name>` (optionally specifying the key type: `aes256-gcm96`, `rsa-4096`, `ecdsa-p256`, etc.), and configured with options like `deletion_allowed`, `exportable` (whether the raw key material can ever be exported — disabled by default for security), and `min_decryption_version`/`min_encryption_version` to control which key versions remain usable. Different key types support different operations — symmetric AES keys support encrypt/decrypt, while asymmetric keys (RSA/ECDSA/Ed25519) support sign/verify and, for RSA, also encrypt/decrypt.

### Key Rotation (Transit)
As covered earlier, `vault write -f transit/keys/<name>/rotate` creates a new key version. Transit retains all historical versions by default (subject to `min_decryption_version`), enabling decryption of data encrypted under any retained version while all new encryptions use the latest. Combined with `rewrap`, organizations can implement periodic key rotation policies (e.g., quarterly) without any data becoming unreadable.

### HMAC
Transit can generate a Hash-based Message Authentication Code for data using a named key: `vault write transit/hmac/<key-name> input=<base64-data>`. HMACs allow verifying both the integrity and authenticity of data (that it hasn't been tampered with and was created by someone with access to the key) without revealing the key itself. This is useful for things like verifying webhook payload signatures or detecting tampering with stored data.

### Signatures
For asymmetric keys, Transit can produce digital signatures (`vault write transit/sign/<key-name> input=<base64-data>`) and verify them (`vault write transit/verify/<key-name> input=<base64-data> signature=<sig>`). This allows Vault to act as a signing authority — for example, signing software artifacts, JWTs, or audit records — where the private signing key never leaves Vault, and any party with the corresponding public key (which *can* be exported even if the private key can't) can verify the signature's authenticity.

### Hashing
Transit also exposes simple hashing functionality (`vault write transit/hash algorithm=sha2-256 input=<base64-data>`), computing a cryptographic hash (SHA-2 family, by default) of input data. While this doesn't require a named key (hashing is keyless), it's included in Transit for convenience so applications can perform consistent, centrally-configured cryptographic operations through a single interface.

## 12. Kubernetes Integration

### Vault on Kubernetes
Vault can run *on* Kubernetes (as a StatefulSet, typically via the official Helm chart) and/or be *used by* workloads running on Kubernetes. When Vault itself runs on Kubernetes, each pod is a Vault server node, often using Integrated Storage (Raft) with persistent volumes for each pod's data directory, and a headless service for inter-node Raft communication. Auto-unseal (via cloud KMS) is strongly recommended in this setup since pods can be rescheduled and restarted by Kubernetes at any time, and manual unsealing after every restart would be impractical.

### Helm Installation
HashiCorp publishes an official Helm chart (`hashicorp/vault`) that simplifies deploying Vault, Vault Agent Injector, and the CSI provider onto Kubernetes. A typical installation is `helm install vault hashicorp/vault -f values.yaml`, where `values.yaml` configures the storage backend (e.g., enabling `server.ha.raft.enabled=true`), TLS settings, resource limits, auto-unseal configuration, and whether to enable the injector (`injector.enabled=true`). After installation, the cluster still needs to be initialized and unsealed (or configured for auto-unseal) before it becomes usable.

### Vault Agent
**Vault Agent** is a client-side daemon that runs alongside an application (as a sidecar container or separate process) and handles authentication and secret retrieval on the application's behalf. It supports **auto-auth** (automatically authenticating to Vault using a configured method like Kubernetes auth, with automatic token renewal) and **templating** (rendering secrets fetched from Vault into files on disk in a specified format, re-rendering when the underlying secret changes or the lease is renewed). This means the application itself doesn't need any Vault-specific code — it just reads a file that Vault Agent keeps populated and up-to-date.

### Injector
The **Vault Agent Injector** is a Kubernetes mutating admission webhook that automatically injects a Vault Agent container into pods that have specific annotations (e.g., `vault.hashicorp.com/agent-inject: "true"`, `vault.hashicorp.com/role: "myapp"`, and annotations specifying which secrets to fetch and how to template them). When such a pod is created, the injector modifies the pod spec on-the-fly to add init and sidecar containers running Vault Agent, configured according to the annotations — meaning developers can opt individual pods into Vault secret injection purely through YAML annotations, without modifying application code or Dockerfiles.

### Sidecar Pattern
In the sidecar pattern, Vault Agent runs as an additional container within the same pod as the application container, sharing a volume (typically an `emptyDir`). Vault Agent authenticates to Vault (using the pod's own service account via Kubernetes auth), fetches and renders secrets into files on the shared volume, and keeps them refreshed. The application container simply reads secret values from files on that shared volume, completely decoupled from how/when those secrets were fetched or rotated. An **init container** variant ensures secrets are present *before* the main application container starts.

### Kubernetes Auth Method
As covered in section 3, the Kubernetes auth method lets pods authenticate using their projected service account JWTs, validated via the Kubernetes TokenReview API. In the context of the Injector/Agent pattern, this is the mechanism Vault Agent uses for auto-auth — the pod's service account identity (namespace + service account name), bound to a Vault role via `bound_service_account_names` / `bound_service_account_namespaces`, determines which policies (and therefore which secrets) the pod can access.

### Secret Injection
"Secret injection" broadly describes the pattern of getting Vault-managed secrets into a running application without the application needing Vault-aware code — achieved either via the Agent Injector sidecar (writing secrets to files) or the CSI driver (mounting secrets as a volume). Either way, from the application's perspective, secrets simply "appear" as files at expected paths, and Vault Agent (or the CSI driver) is responsible for fetching, rendering, and refreshing them according to their lease lifecycle.

### CSI Driver
The **Vault CSI Provider** implements the [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/) interface, allowing Vault secrets to be mounted directly as files in a pod via a standard Kubernetes `volume` of type `csi`, referencing a `SecretProviderClass` that specifies which Vault secrets to fetch and how. Unlike the Agent Injector (which adds sidecar containers), the CSI driver runs as a DaemonSet and mounts secrets at the kubelet level — some teams prefer this because it avoids adding extra containers to every pod, though it has different refresh/rotation characteristics (secrets are typically re-synced on a poll interval rather than continuously renewed by an in-pod agent).

### Dynamic Secrets for Pods
Combining dynamic secrets engines (Database, AWS, PKI, etc.) with Kubernetes auth and Agent/CSI injection means a pod can start up, authenticate as itself (via its service account), and receive freshly-generated, pod-specific dynamic credentials (e.g., its own unique database user) — with those credentials automatically revoked when the pod terminates and its Vault token/lease expires. This is one of the most powerful patterns in cloud-native Vault usage: no static secrets are baked into images, ConfigMaps, or even Kubernetes Secrets at all.

---

## 13. Vault Agent (Detailed)

### Auto Authentication
Vault Agent's **auto-auth** subsystem handles the entire authentication lifecycle: it's configured with a `method` block specifying the auth method (Kubernetes, AppRole, AWS, Azure, GCP, JWT, etc.) and method-specific parameters (e.g., the role name and service account token path for Kubernetes auth). On startup, Agent performs the login automatically, obtains a token, and writes it to a configured **sink** (a file) if needed by other processes, while keeping the token in memory for its own template-rendering use. If the token expires or authentication needs to be redone (e.g., for AppRole with a single-use Secret ID supplied externally), Agent handles re-authentication transparently.

### Token Renewal
Once authenticated, Vault Agent automatically manages **token renewal** — it tracks the token's TTL and proactively renews it (via the standard renew API) before expiration, as long as the token remains renewable and hasn't hit its `max_ttl`. This relieves applications of needing any token lifecycle logic; as far as the application is concerned, Agent simply "always has a valid token" for fetching secrets, for as long as Agent itself is running and the underlying auth method credentials remain valid.

### Template Rendering
Vault Agent's **templating** feature uses Consul Template syntax to define how data fetched from Vault should be rendered into files. A template configuration specifies a source template file (or inline template) containing placeholders like `{{ with secret "database/creds/myrole" }}{{ .Data.username }}:{{ .Data.password }}{{ end }}`, and a destination file path. Agent renders this template whenever the underlying secret changes (e.g., a new lease is issued on renewal/rotation) and can optionally run a `command` after rendering (e.g., to signal the application to reload its configuration), enabling fully automated credential rotation without application restarts.

### Secret Caching
Vault Agent can run a local caching proxy — applications send normal Vault API requests to Agent's local listener instead of directly to the Vault server, and Agent caches responses (particularly token and lease information), serving repeated requests from cache where appropriate and automatically handling renewal of cached leases in the background. This reduces load on the Vault server in scenarios with many short-lived processes or frequent secret reads, and can provide a degree of resilience to brief Vault outages for already-cached data.

### Agent Sidecar
"Agent sidecar" refers to the deployment pattern (discussed in section 12) of running Vault Agent as a dedicated container alongside the application container within the same pod, sharing volumes for rendered secrets/tokens. This is the most common production pattern for Kubernetes workloads, combining auto-auth (using the pod's Kubernetes identity), templating (rendering dynamic database credentials, PKI certificates, etc. to shared files), and optionally caching — all configured declaratively via pod annotations processed by the Agent Injector.

---

## 14. High Availability (HA)

### HA Architecture
Vault HA is built around a cluster of Vault server nodes that all point at the same (replicated) storage backend, with exactly one node designated **active** at any time and the rest as **standby**. All client requests are served by the active node; standby nodes either redirect/proxy requests to the active node or (in Enterprise, with Performance Standby) can serve certain read-only requests directly. If the active node fails or becomes unreachable, the cluster automatically elects a new active node from the remaining healthy standbys, typically within seconds, with minimal disruption to clients (especially when clients are configured to retry against a load-balanced VIP or DNS name pointing at the whole cluster).

### Active Node
The active node is the single Vault server currently responsible for processing all read and write requests, holding the unsealed in-memory encryption key, and running background processes like lease expiration and replication (if configured). Only the active node writes to the shared storage backend's "leadership" indicators; other nodes continuously check whether they should attempt to become active.

### Standby Node
Standby nodes are fully unsealed Vault servers that are *not* currently serving requests — they're "hot" backups, ready to become active immediately if needed, but in OSS they don't serve client traffic themselves (they typically respond to API requests with a redirect to the active node's address, often handled transparently by a load balancer). Standby nodes continuously replicate state from the storage backend (in Raft, via the Raft log; in Consul, via Consul's own replication) so they're always nearly caught-up and ready to take over.

### Leader Election
Leader election is the process by which Vault nodes agree on which single node is "active." With Integrated Storage, this is handled by the **Raft consensus protocol** itself — Raft elects a leader among the storage nodes, and that Raft leader becomes the active Vault node. With Consul storage, Vault nodes use Consul's **session and lock** primitives — each standby attempts to acquire a lock in Consul, and whichever node successfully acquires it becomes active; if the active node fails to renew its session (e.g., it crashes), the lock is released and another standby acquires it, becoming the new active node.

### Raft Cluster
A Raft cluster (when using Integrated Storage) consists of an odd number of voting nodes (commonly 3, 5, or 7 — odd numbers avoid split-vote ties and provide clear majority thresholds) that replicate a log of all state changes. New nodes join via `vault operator raft join <leader-api-addr>`, after which they receive a snapshot of current state and begin replicating new log entries. The cluster tolerates the failure of up to `(n-1)/2` nodes while maintaining quorum (and thus availability) — e.g., a 5-node cluster tolerates 2 simultaneous node failures. `vault operator raft list-peers` shows current cluster membership and each node's voter/non-voter status and health.

### Storage Replication
"Storage replication" in the HA context refers to how the chosen storage backend propagates data to all nodes — Raft's log replication (for Integrated Storage) or Consul's own internal replication (for Consul storage backend). This is distinct from **Performance/DR Replication** (Enterprise features, covered in section 15), which replicate data *between separate Vault clusters* (potentially in different regions/datacenters), whereas storage replication keeps nodes *within a single cluster* in sync.

### Performance Tuning
HA performance considerations include: placing cluster nodes with low-latency network links between them (Raft consensus requires quorum acknowledgment for every write, so high inter-node latency directly impacts write throughput), sizing storage appropriately (Raft's data directory should be on fast disk — NVMe/SSD — since it's both the database and the replication log), tuning cache sizes and `default_lease_ttl`/`max_lease_ttl` to manage the volume of active leases the expiration manager must track, and (in Enterprise) using **Performance Standby Nodes** to horizontally scale read-heavy workloads, since standbys can serve many read-only requests (including token validation and many secret reads) without forwarding to the active node.

---

## 15. Disaster Recovery

### Backup Strategy
A robust Vault backup strategy centers on regular **Raft snapshots** (for Integrated Storage) or equivalent backend-specific backups (for Consul, this means backing up Consul's data), combined with secure off-cluster storage of **unseal keys / recovery keys** and the **root token** (or a documented process to regenerate one). Backups should be tested periodically by performing actual restores in a non-production environment — an untested backup is not a reliable backup. Configuration files, TLS certificates, and policy definitions (ideally version-controlled separately) should also be included in the overall recovery plan.

### Snapshot Creation
With Integrated Storage, `vault operator raft snapshot save <path>` creates a point-in-time snapshot of the entire Raft state (encrypted, as all Vault data is). This can be run on a schedule (e.g., via cron or a Kubernetes CronJob) against the active node, and the resulting snapshot file should be copied to durable, geographically-separate storage (e.g., object storage in another region). Snapshots capture everything — secrets engine configuration, policies, leases, and (encrypted) secret data — but **not** the unseal/recovery keys, which must be backed up separately and just as carefully.

### Snapshot Restore
`vault operator raft snapshot restore <path>` restores Vault's entire state from a previously-taken snapshot, effectively rolling the cluster back to that point in time. This is a significant operation — typically used for disaster recovery (rebuilding a cluster from scratch after total loss) or for deliberately reverting unwanted changes — and requires the Vault cluster to be unsealed with the *same* unseal/recovery keys that were valid at the time the snapshot was taken (since the snapshot's data is encrypted with that era's encryption key, itself protected by the root key).

### DR Replication
**Disaster Recovery (DR) Replication** (Vault Enterprise) continuously replicates the *entire state* of a primary Vault cluster to one or more secondary "DR" clusters, typically in a different region or datacenter. DR secondary clusters are **standby-only** — they don't serve any client requests (not even reads) under normal operation; their sole purpose is to be promoted to primary if the original primary cluster becomes unavailable, providing a region-level failover capability. Promotion is a deliberate administrative action (`vault operator step-down`/promotion commands), not automatic, since failing over to a DR cluster that's slightly behind the primary involves some data-loss tradeoff considerations.

### Performance Replication
**Performance Replication** (Vault Enterprise) is designed for scaling reads across geographic regions rather than disaster recovery — a primary cluster replicates most data to one or more performance secondary clusters, which **can** actively serve requests (particularly reads and many dynamic secret generation operations) using locally-cached policy and configuration data, reducing latency for geographically distributed clients. Unlike DR replication, performance secondaries are live, request-serving clusters, though certain operations (like modifying core configuration) may still need to be forwarded to the primary.

### Multi-Region Vault
Combining Performance Replication (for low-latency reads across regions) and DR Replication (for failover) enables a "multi-region Vault" architecture: a primary cluster in one region, performance secondaries in other regions for local read traffic, and DR secondaries (potentially of the primary and/or performance clusters) standing by for regional outages. Designing such topologies requires careful thought about which secrets engines/auth methods are "local" vs need cross-region consistency, since some dynamic secret operations (those requiring write access to a primary) may always need to traverse to whichever cluster is currently primary.

## 16. Monitoring & Logging

### Audit Devices
Audit devices are the pluggable backends that receive Vault's audit log entries — every request received and every response sent (with sensitive fields HMAC'd, as described in section 7). Multiple audit devices can be enabled simultaneously for redundancy. Enabling an audit device is done with `vault audit enable <type> ...`, and if every enabled device becomes unavailable, Vault blocks all further requests rather than proceed without logging — a deliberate fail-closed safety property that operators must account for in capacity planning (e.g., ensuring the audit log filesystem never fills up).

### File Audit Logs
The `file` audit device writes audit log entries as newline-delimited JSON to a specified file path (`vault audit enable file file_path=/var/log/vault/audit.log`). This is the simplest audit device and is commonly paired with log rotation tools (logrotate) and forwarding agents (Filebeat, Fluentd) that ship the logs to a centralized logging platform (Splunk, ELK, Datadog) for long-term retention, search, and alerting.

### Syslog Audit Logs
The `syslog` audit device sends audit entries to the host's syslog daemon (`vault audit enable syslog`), which can then be configured to forward to remote syslog servers or SIEM platforms. This is useful in environments where syslog-based centralized logging is already the standard, avoiding the need for a separate file-based shipping pipeline. A `socket` audit device type also exists for sending audit logs directly over TCP/UDP to a remote listener.

### Metrics Collection
Vault emits detailed operational metrics (request counts and latencies per route, token/lease counts, storage backend performance, replication status, and more) via a `telemetry` configuration block. Vault supports multiple metrics sinks including **StatsD**, **Circonus**, and — most commonly in modern stacks — a **Prometheus-compatible `/v1/sys/metrics` endpoint** (enabled with `telemetry { prometheus_retention_time = "24h" disable_hostname = true }` and requiring a token with appropriate permissions, or `unauthenticated_metrics_access` for simpler setups).

### Prometheus Integration
With `telemetry.prometheus_retention_time` configured, Vault exposes metrics in Prometheus exposition format at `/v1/sys/metrics?format=prometheus`. A Prometheus server scrapes this endpoint on a regular interval, storing time-series data such as request rates, error rates, seal status, lease counts, and Raft/replication health indicators. This integration is foundational for both dashboarding (via Grafana) and alerting (via Prometheus Alertmanager) on Vault's operational health.

### Grafana Dashboards
Grafana dashboards built on top of Vault's Prometheus metrics provide visual operational views — typical panels include request rate and latency by endpoint, seal status across cluster nodes, active vs standby node identification, lease creation/expiration rates, token creation rates, Raft replication lag, and audit device health. HashiCorp and the community publish reference Grafana dashboards (importable by dashboard ID) that provide a solid starting point, which teams then customize with environment-specific alert thresholds.

### Health Checks
Vault exposes a `/v1/sys/health` endpoint specifically designed for use by load balancers and health-check systems. It returns different HTTP status codes depending on Vault's state — by default, 200 for an active/unsealed node, 429 for a standby node (useful for load balancers to route only to the active node), 472/473 for DR secondary/performance standby nodes (Enterprise), and 503 for a sealed node. Operators can customize these status codes via query parameters, and this endpoint is the standard way to configure load balancer health checks so traffic is automatically routed only to a healthy, active node.

### Troubleshooting
Common Vault troubleshooting techniques include: checking `vault status` for seal state, HA status, and Raft peer information; reviewing server logs for errors (especially around storage backend connectivity and TLS handshake failures); using `vault operator raft list-peers` and replication status endpoints to diagnose cluster health; checking `/v1/sys/health` from each node to identify which is active; reviewing audit logs to trace exactly what a failing request looked like and what response/error Vault returned; and using `VAULT_LOG_LEVEL=trace` (or the `log_level` config option) for more verbose diagnostic output when investigating subtle issues like auth method misconfigurations or policy denials (where the audit log will show the specific path and capability that was denied).

---

## 17. Vault Enterprise Features

### Namespaces
Namespaces provide **multi-tenancy** within a single Vault Enterprise cluster — each namespace is an isolated environment with its own auth methods, secrets engines, policies, and identity store, administratively separate from other namespaces, while still sharing the underlying cluster infrastructure (and, optionally, replication configuration). This allows, for example, a platform team to operate one Vault cluster that hosts separate, independently-administered namespaces for different business units or environments (dev/staging/prod), each with delegated administrators who can't see or affect other namespaces.

### Sentinel Policies
**Sentinel** is HashiCorp's policy-as-code framework, integrated into Vault Enterprise to provide policy capabilities beyond what ACL policies can express. While ACL policies are essentially path + capability matching, Sentinel policies can evaluate arbitrary logic against the full context of a request — for example, requiring MFA for requests outside business hours, restricting certain operations based on the requesting entity's metadata, or enforcing organizational naming conventions on newly-created secrets engine mounts. Sentinel policies can be set to `advisory` (logged but not enforced) or `hard-mandatory`/`soft-mandatory` (enforced, blocking non-compliant requests).

### HSM Integration
Hardware Security Module (HSM) integration allows Vault's root key to be protected by a physical or cloud HSM rather than (or in addition to) Shamir key shares — similar in effect to cloud auto-unseal (AWS KMS/Azure Key Vault/GCP KMS) but using on-premises or dedicated HSM hardware (e.g., via PKCS#11). This is often a compliance requirement in regulated industries where key material must be protected by FIPS-140-2-validated hardware. HSM-backed seals were historically an Enterprise-only feature, distinguishing them from the cloud KMS auto-unseal options which have broader availability.

### Performance Replication (Enterprise)
Covered in section 15 — included again here as a headline Enterprise feature because it's central to large multi-region Enterprise deployments, enabling geographically distributed read scaling with active secondary clusters.

### Disaster Recovery Replication (Enterprise)
Also covered in section 15 — DR Replication is the other half of Enterprise's replication offering, providing standby-only secondary clusters for regional failover scenarios.

### Multi-Tenancy
Beyond namespaces specifically, "multi-tenancy" in Vault Enterprise encompasses the broader set of capabilities that let a single Vault deployment safely serve many independent teams/customers — namespaces for isolation, **resource quotas** (limiting request rates or lease counts per namespace/mount to prevent one tenant from degrading service for others), and delegated administration (namespace admins can manage their own auth methods and policies without needing cluster-wide root access). This is especially relevant for platform teams offering "Vault as a Service" internally across an organization, or for managed service providers offering Vault to external customers.

---

## 18. CI/CD Integration

### Jenkins + Vault
Jenkins integrates with Vault primarily via the **HashiCorp Vault Plugin**, which allows pipeline steps to fetch secrets from Vault and inject them as environment variables or files during a build, without those secrets being stored in Jenkins credentials configuration. Authentication is typically via AppRole (Jenkins holds a Role ID and Secret ID, often itself stored in Jenkins' credential store or fetched from a more privileged Vault path at pipeline start) or, in Kubernetes-based Jenkins agents, via Kubernetes auth using the agent pod's service account. A `withVault` block in a `Jenkinsfile` declares which secrets to fetch and how to expose them to subsequent steps.

### GitLab CI + Vault
GitLab CI has built-in support for fetching secrets from Vault using **JWT-based authentication** — GitLab CI can generate an `ID_TOKEN` (a signed JWT containing claims about the pipeline, project, and ref) that's configured as the credential for Vault's JWT auth method. Vault roles bind specific claims (project path, ref/branch, etc.) to policies, so a pipeline running on the `main` branch of a specific project can be granted access to production secrets, while pipelines on feature branches are restricted to non-production secrets — all without any static AppRole credentials stored in GitLab.

### GitHub Actions + Vault
Similarly, GitHub Actions supports OIDC token generation, and HashiCorp provides an official `hashicorp/vault-action` GitHub Action that uses this OIDC token to authenticate to Vault's JWT/OIDC auth method and fetch secrets, exposing them as step outputs or environment variables for subsequent steps. Vault roles bind claims like the repository name, branch/ref, and workflow name, enabling fine-grained, identity-based access without long-lived GitHub secrets stored in repository settings.

### Terraform + Vault
The **Terraform Vault provider** (`hashicorp/vault`) allows Terraform configurations to both *read* secrets from Vault (e.g., a `vault_generic_secret` or `vault_kv_secret_v2` data source to retrieve a database password used to configure another resource) and *manage Vault's own configuration as infrastructure* (creating policies, enabling auth methods and secrets engines, configuring roles — `vault_policy`, `vault_auth_backend`, `vault_database_secret_backend_role`, etc.). The latter pattern — "Vault configuration as code" — is widely used so that Vault's policy and engine setup is version-controlled, reviewed, and reproducible alongside the rest of an organization's infrastructure.

### Ansible + Vault
Ansible integrates with Vault primarily through **lookup plugins** (`community.hashi_vault` collection), allowing playbooks to retrieve secrets at runtime (`lookup('hashi_vault', 'secret=secret/data/myapp:password token=...')`) for use in templates or variable assignments, without secrets being stored in plaintext in playbooks or inventory files. Authentication can use tokens, AppRole, or other methods supported by the collection. (Note: this Vault integration is distinct from "Ansible Vault," which is Ansible's own separate, unrelated file-encryption feature for encrypting variables/files within a playbook repo.)

### Secret Injection in Pipelines
Across all these integrations, the common pattern is: the CI/CD platform's pipeline obtains a short-lived, identity-bound credential (an OIDC/JWT token tied to the specific pipeline run, or an AppRole Secret ID with restricted scope), exchanges it for a Vault token, fetches only the specific secrets needed for that pipeline run, and those secrets exist only in the pipeline's ephemeral environment/memory — never persisted in the CI platform's own secret storage, version control, or build artifacts. This minimizes the blast radius of a compromised CI runner and ensures secret access is auditable per pipeline run via Vault's audit logs.

---

## 19. Cloud Integrations

### AWS IAM Auth
Covered in depth in section 3 — the AWS auth method's IAM-based login flow is the primary mechanism for AWS workloads (EC2, ECS, Lambda, EKS via IRSA) to authenticate to Vault using their existing IAM role, by having Vault verify a signed `sts:GetCallerIdentity` request on the workload's behalf. This is the foundation for most AWS-Vault integration patterns since it requires no static credentials to be distributed to the workload at all — the IAM role attached to the compute resource is sufficient.

### AWS Dynamic Credentials
Covered in section 6 — the AWS secrets engine generates temporary IAM credentials (via dynamic IAM users or STS AssumeRole/federation tokens) for applications that need to call AWS APIs themselves. Combined with AWS IAM auth (for the application to authenticate *to* Vault) and the AWS secrets engine (for Vault to issue temporary credentials *for AWS*), an application can go from "has an EC2 instance role" to "has short-lived, scoped AWS API credentials for a completely different purpose/permission set" without any static AWS keys ever existing.

### Azure Secrets (Cloud Integration Context)
In the broader cloud integration context, Azure Secrets Engine usage typically pairs with **Azure auth method** for the consuming application's identity — an application running on an Azure VM with a managed identity authenticates to Vault via Azure auth, and is then authorized (via policy) to request dynamic Azure service principal credentials from the Azure secrets engine, potentially for a completely different subscription or with different permissions than the VM's own managed identity has.

### GCP Secrets (Cloud Integration Context)
Similarly, GCP workloads commonly use the **GCP auth method** (via their attached service account identity) to authenticate to Vault, then request dynamic credentials (OAuth tokens or service account keys) from the **GCP secrets engine** for accessing other GCP resources/projects — enabling fine-grained, time-limited, audit-tracked access patterns that go beyond what the workload's own statically-assigned service account permissions would allow.

### Multi-Cloud Secret Management
Vault's auth method and secrets engine plugin architecture means a single Vault deployment can serve as the **central secrets management plane across multiple clouds simultaneously** — an organization might have workloads in AWS, Azure, and GCP all authenticating to the same Vault cluster via their respective native cloud auth methods, with policies and secrets engines configured per-cloud as needed, but with unified audit logging, policy management, and identity (entities/groups) spanning all of them. This avoids the need for separate, cloud-specific secrets management tooling (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager) in each environment, centralizing operational knowledge and audit trails into one system.

---

## 20. Advanced Topics

### Vault Performance Optimization
Beyond the HA-focused tuning in section 14, broader performance optimization includes: choosing appropriate `default_lease_ttl`/`max_lease_ttl` values (excessively short TTLs on high-volume dynamic secrets can create churn — constant credential generation/revocation — that stresses both Vault and the backend systems like databases); enabling **Performance Standby Nodes** (Enterprise) to offload read traffic from the active node; tuning the storage backend (fast local NVMe for Raft, appropriately-sized Consul clusters); minimizing the number of policies attached to frequently-used tokens (policy evaluation has a cost, though usually small); and using **batch tokens** for high-volume, short-lived authentication scenarios to avoid service-token storage overhead.

### Auto Unseal using AWS KMS
Configured via a `seal "awskms" { region = "us-east-1" kms_key_id = "<key-id>" }` block in Vault's configuration. Vault uses AWS credentials (via instance profile, environment variables, or explicit config) to call AWS KMS's `Encrypt`/`Decrypt` APIs, using the specified KMS key to protect Vault's root key. On startup, Vault calls KMS to decrypt the stored, KMS-encrypted root key material, automatically unsealing without operator intervention. The KMS key's IAM policy should tightly restrict which principals can use it for decrypt operations, since access to that KMS key is functionally equivalent to being able to unseal Vault.

### Auto Unseal using GCP KMS
Configured via `seal "gcpckms" { project = "<project>" region = "<region>" key_ring = "<ring>" crypto_key = "<key>" }`. Vault authenticates to Google Cloud (via a service account, often through Workload Identity if running on GKE) with permission to use the specified Cloud KMS key for encrypt/decrypt, following the same overall pattern as AWS KMS auto-unseal — the root key material is encrypted by the GCP KMS key, and Vault calls KMS on startup to decrypt it.

### Auto Unseal using Azure Key Vault
Configured via `seal "azurekeyvault" { tenant_id = "..." vault_name = "..." key_name = "..." }`. Vault authenticates to Azure AD (via a service principal or managed identity) with permissions to wrap/unwrap keys in the specified Azure Key Vault, and uses that key to protect its root key material in the same auto-unseal pattern as the AWS and GCP options.

### HSM Integration (Advanced)
For organizations with on-premises HSMs or specific FIPS/compliance requirements that cloud KMS auto-unseal doesn't satisfy, Vault Enterprise supports **PKCS#11-based HSM seals**, where the root key is wrapped by a key held in the HSM. This requires the Vault server to have network access to the HSM (or a PKCS#11 library/driver for a directly-attached HSM) and is generally more operationally complex than cloud KMS options, reserved for environments where cloud KMS isn't an acceptable option for regulatory reasons.

### Secrets Rotation Automation
At an advanced level, "secrets rotation automation" extends beyond Vault's built-in dynamic secret leasing to cover **root credential rotation** for secrets engines themselves (e.g., `vault write -f database/rotate-root/<connection-name>` rotates the admin password Vault uses to connect to a database, with Vault generating and storing the new password — meaning even Vault administrators no longer know the current root credential), and orchestrating rotation of credentials for systems that Vault doesn't natively manage (via custom scripts/plugins that follow the same rotate-and-update pattern), often triggered on a schedule via external automation calling Vault's rotation endpoints.

### Vault Cluster Scaling
Scaling a Vault cluster involves both **vertical scaling** (larger nodes — more CPU/memory for handling more concurrent requests and larger numbers of tracked leases) and **horizontal scaling** via Performance Standby Nodes (Enterprise) for read throughput, or via Performance Replication secondaries in additional regions for geographic scaling. For Integrated Storage, adding nodes to the Raft cluster (`vault operator raft join`) increases fault tolerance but does not directly increase write throughput (since all writes go through the single active node and require quorum acknowledgment) — write scaling is fundamentally limited by the active node and inter-node network latency, which is why very write-heavy designs sometimes favor minimizing dynamic secret churn (see Performance Optimization) over simply adding nodes.

### Security Hardening
Vault security hardening recommendations (per HashiCorp's production hardening guide) include: always running with TLS enabled on all listeners and disabling any non-TLS endpoints; running Vault as a non-root OS user with minimal filesystem permissions on config/data directories; enabling `mlock` to prevent secret material from being swapped to disk; disabling the Vault UI in highly sensitive environments if not needed (`ui = false`) or restricting network access to it; using short token TTLs and preferring dynamic secrets over long-lived static ones; enabling and monitoring audit logging from day one; restricting root token usage as described in section 5; and keeping Vault itself up to date with security patches, since Vault is high-value attack surface by design.

### Zero Trust Architecture
Vault is a foundational component in many zero-trust architectures, which operate on the principle of "never trust, always verify" — no implicit trust based on network location (e.g., being "inside the corporate network" grants nothing). Vault contributes to zero trust by: providing **identity-based access** (every request must authenticate via a verifiable identity — cloud IAM role, Kubernetes service account, mTLS certificate, etc. — rather than relying on network-perimeter trust), issuing **short-lived credentials** everywhere possible (so even a fully-authenticated identity's access is time-bound), and centralizing **policy enforcement and audit** (every access decision and its outcome is logged and attributable to a specific identity). PKI-issued short-lived certificates for mTLS between services is a particularly common zero-trust pattern built on Vault.

### Service Mesh Integration
Service meshes (Consul Connect, Istio, Linkerd) handle mTLS between services within the mesh, and Vault commonly integrates as the **certificate authority backing the mesh's mTLS** — rather than the mesh's built-in CA, the mesh is configured to request intermediate CA certificates (or have Vault sign certificates directly) from Vault's PKI secrets engine, centralizing certificate issuance, rotation, and revocation policy in Vault alongside all other secrets management, and leveraging Vault's existing audit logging and access control for the mesh's CA operations as well.

---

## 21. Interview-Focused Hands-on Projects

### Vault + Kubernetes Secret Injection
A complete hands-on project covering: deploying Vault on Kubernetes via Helm (or connecting to an external Vault), enabling and configuring the Kubernetes auth method (creating a service account for Vault to use as the token reviewer, configuring `auth/kubernetes/config` with the cluster's CA cert and API address), writing a policy granting read access to a specific KV path, creating a Vault role binding a Kubernetes service account/namespace to that policy, deploying the Agent Injector, and annotating a sample application's pod spec to inject secrets — then verifying the application can read the injected secret file. This demonstrates the full chain from Kubernetes identity to Vault policy to secret delivery, a very commonly discussed interview scenario.

### Vault + Jenkins Dynamic Secrets
A project demonstrating: configuring the database secrets engine with dynamic credentials for a sample database, enabling AppRole auth and creating a role/policy granting access to those dynamic credentials, configuring the Jenkins Vault plugin with the AppRole Role ID/Secret ID, and writing a `Jenkinsfile` that fetches a fresh database credential at the start of a pipeline run, uses it to run a database migration or test step, and observes (via Vault's audit log and the database's own connection logs) that a unique, short-lived credential was used for that specific pipeline run and automatically revoked afterward.

### Vault + PostgreSQL Dynamic Credentials
A focused project on the database secrets engine: standing up a PostgreSQL instance, creating a Vault-managed admin user with `CREATEROLE` privileges, configuring the `database/config` connection and a role with appropriate `creation_statements`/`revocation_statements`, requesting credentials via `vault read database/creds/<role>`, connecting to PostgreSQL with those credentials to confirm they work and have the expected (limited) privileges, then either waiting for the lease to expire or running `vault lease revoke` and confirming the dynamically-created PostgreSQL role no longer exists.

### Vault + AWS IAM Authentication
A project covering: enabling the AWS auth method, configuring it with appropriate AWS credentials for STS validation, creating an IAM role for an EC2 instance (or simulating the IAM principal locally with AWS CLI credentials), creating a Vault role with `auth_type=iam` and a `bound_iam_principal_arn` matching that role/user, and demonstrating login via `vault login -method=aws` (which signs and submits the `GetCallerIdentity` request) — resulting in a Vault token whose policies are determined entirely by the AWS IAM identity, with no Vault-specific credentials ever provisioned to the EC2 instance.

### Vault Transit Encryption for Applications
A project demonstrating encryption-as-a-service: enabling the Transit engine, creating a named encryption key, writing a small application (in any language using Vault's API/SDK) that encrypts sensitive fields (e.g., PII) before storing them in a database and decrypts them on read, then demonstrating key rotation (`transit/keys/<name>/rotate`) followed by `rewrap` on previously-stored ciphertext to migrate it to the new key version — illustrating how applications can be "key-material-free" while still using strong encryption.

### Vault HA Cluster with Raft
A project building a 3-node Vault cluster using Integrated Storage: configuring each node's `storage "raft"` block with unique `node_id`s and `retry_join` stanzas pointing at the other nodes, initializing the cluster on the first node, joining the other two nodes (`vault operator raft join`), unsealing all three nodes, then using `vault operator raft list-peers` to confirm cluster membership and identify the active node — followed by deliberately stopping the active node's process and observing automatic leader election promote one of the standbys, with minimal client-visible disruption.

### Vault Auto-Unseal using AWS KMS
A project configuring a Vault server with a `seal "awskms"` stanza pointing at a KMS key created specifically for this purpose, with an IAM policy/role granting the Vault server's identity (instance profile or IAM user) `kms:Encrypt`/`kms:Decrypt`/`kms:DescribeKey` on that key. After `vault operator init`, the output shows **recovery keys** instead of traditional unseal keys. The project demonstrates restarting the Vault process/container and observing it automatically transition to unsealed without any `vault operator unseal` commands, by virtue of successfully calling KMS on startup.

### Vault Monitoring using Prometheus & Grafana
A project enabling Vault's `telemetry` block for Prometheus metrics, deploying a Prometheus server configured to scrape Vault's `/v1/sys/metrics` endpoint (with an appropriately-scoped token if `unauthenticated_metrics_access` isn't enabled), importing or building a Grafana dashboard against that Prometheus data source, and demonstrating key panels (seal status, request rates, lease counts) — potentially also configuring a Prometheus alerting rule (e.g., alert if a node reports sealed status) to demonstrate end-to-end operational monitoring.

### Vault + Terraform Integration
A project using the Terraform Vault provider to manage Vault configuration as code: writing Terraform that defines an ACL policy (`vault_policy`), enables and configures a secrets engine (e.g., `vault_mount` + `vault_database_secret_backend_connection` + `vault_database_secret_backend_role`), enables an auth method and creates a role (`vault_auth_backend` + `vault_kubernetes_auth_backend_role` or similar) — then applying this configuration and demonstrating that the resulting Vault setup matches the Terraform state, with subsequent changes to the `.tf` files producing corresponding, reviewable diffs (`terraform plan`) before being applied.

### Vault Disaster Recovery Setup
A project (requiring Vault Enterprise, or simulated conceptually with OSS via manual snapshot/restore) covering: taking regular Raft snapshots (`vault operator raft snapshot save`) on a schedule, storing them in a separate location, and performing a full disaster-recovery drill — standing up a brand-new Vault cluster, restoring the most recent snapshot (`vault operator raft snapshot restore`), unsealing it with the original unseal/recovery keys, and verifying that secrets engines, policies, and (where applicable) leases are restored as expected — documenting the recovery time and any manual steps required, which is exactly the kind of operational readiness interviewers look for from senior DevOps candidates.

---

## DevOps Engineer (5+ years) — Priority Focus Map

For an experienced DevOps engineer, the most interview-relevant areas — all covered in detail above — are: **Vault Fundamentals** (sections 1–2: architecture, init/unseal, storage backends), **Authentication Methods** (section 3, especially AppRole, Kubernetes, and AWS auth), **Policies & Tokens** (sections 4–5: ACL syntax, capabilities, token types and lifecycle), **KV and Dynamic Secrets Engines** (section 6 and 9: KV v2 versioning, database dynamic credentials), **Transit Engine** (sections 6 and 11: encryption as a service, key rotation), **Kubernetes Integration** (section 12: Agent Injector, CSI driver, dynamic secrets for pods), **Vault Agent** (section 13: auto-auth, templating, sidecar pattern), **HA & Raft Storage** (section 14), **DR & Replication** (section 15), **CI/CD Integration** (section 18: Jenkins, GitLab CI, GitHub Actions, Terraform), and **Monitoring & Troubleshooting** (section 16: Prometheus/Grafana, health checks, audit logs). The hands-on projects in section 21 map directly onto these priority areas and are excellent practice for live technical interviews or take-home assessments.
