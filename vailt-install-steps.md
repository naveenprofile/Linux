Here is the complete sequence of everything you did to install and configure HashiCorp Vault on your RHEL/CentOS Stream server.

1. Install Vault

Update the system:

sudo dnf update -y

Install required packages:

sudo dnf install -y dnf-plugins-core wget unzip

Add the HashiCorp repository and install Vault:

sudo dnf install -y vault

Verify:

vault version
2. Create directories
sudo mkdir -p /etc/vault.d
sudo mkdir -p /opt/vault/data
3. Configure Vault

Edit:

sudo vi /etc/vault.d/vault.hcl

Configuration:

ui = true

disable_mlock = true

api_addr = "http://10.128.0.22:8200"

storage "file" {
  path = "/opt/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
4. Start and enable Vault
sudo systemctl daemon-reload
sudo systemctl enable vault
sudo systemctl start vault

Check status:

systemctl status vault
5. Configure CLI
export VAULT_ADDR=http://127.0.0.1:8200

Permanent:

echo "export VAULT_ADDR=http://127.0.0.1:8200" >> ~/.bashrc
source ~/.bashrc
6. Check Vault status
vault status

Initially:

Initialized: false
Sealed: true
7. Initialize Vault
vault operator init

Vault generated:

5 Unseal Keys
1 Initial Root Token

Save these securely.

8. Unseal Vault

Run three times:

vault operator unseal

Paste:

Unseal Key 1
Unseal Key 2
Unseal Key 3

Verify:

vault status

Expected:

Initialized true
Sealed false
9. Login
vault login

Paste the Initial Root Token.

Verify:

vault token lookup
10. Check Secrets Engines
vault secrets list -detailed

Initially you saw:

agent-registry/
cubbyhole/
identity/
sys/

There was no secret/ mount.

11. Enable KV v2
vault secrets enable -path=secret kv-v2

Verify:

vault secrets list -detailed

Now:

secret/

appears.

12. Store a secret
vault kv put secret/myapp username=admin password=RedHat123
13. Read the secret
vault kv get secret/myapp
14. List secrets
vault kv list secret
15. Restart Vault
sudo systemctl restart vault

Vault becomes sealed.

Check:

vault status
16. Unseal after restart

Run three times:

vault operator unseal

Use any 3 of the 5 unseal keys.

17. Access the Web UI

Initially, Vault listened only on:

address = "127.0.0.1:8200"

You changed it to:

address = "0.0.0.0:8200"

Restarted Vault:

sudo systemctl restart vault
18. Open GCP Firewall

Create an ingress firewall rule allowing:

TCP 8200

Source:

0.0.0.0/0

(For a lab environment. Restrict this in production.)

19. Access the UI

Open:

http://10.128.0.22:8200

The first page is:

Unseal Vault

Enter:

Unseal Key 1
Unseal Key 2
Unseal Key 3

After that, the login page appears.

Choose:

Token

Enter the Root Token.

Commands you learned
vault status
vault operator init
vault operator unseal
vault login
vault token lookup
vault secrets list
vault secrets enable -path=secret kv-v2
vault kv put
vault kv get
vault kv list
systemctl status vault
systemctl restart vault
