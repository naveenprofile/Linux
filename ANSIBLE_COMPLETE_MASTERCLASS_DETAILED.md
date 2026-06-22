# 🎓 ANSIBLE COMPLETE MASTERCLASS - DETAILED EXPLANATIONS FOR EVERYTHING
## The Ultimate Guide - Every Topic Explained in Complete Detail

---

# SECTION 1: ANSIBLE FUNDAMENTALS - COMPLETE EXPLANATION

## What is Ansible? (Complete)

### Definition
Ansible is an **agentless IT automation platform** that simplifies configuration management, application deployment, infrastructure provisioning, and cloud orchestration using SSH and YAML.

### Why This Matters (Business Impact)

**Real Scenario: Deploy Security Patch to 500 Servers**

WITHOUT Ansible:
- 5 engineers × 3 minutes per server = 1500 minutes
- That's 25 hours of human time = $2,500+ in salaries
- High error rate (some servers might be missed)
- Takes entire business day
- Risk window of 24+ hours where servers vulnerable

WITH Ansible:
- 1 engineer × 15 minutes total
- $25 in salary
- 100% consistency (exact same on all 500 servers)
- Done in 15 minutes (vs 25 hours)
- All servers verified automatically

**Business Impact:** 94% faster, 99% cheaper, 100% more reliable

### How Ansible Works (Step-by-Step)

```
STEP 1: You write a playbook (automation recipe)
        File: deploy.yml
        Contains: "Install nginx, configure it, start it"

STEP 2: You run the playbook
        Command: ansible-playbook deploy.yml -i inventory.ini

STEP 3: Ansible reads playbook and inventory
        Playbook: "What tasks to run"
        Inventory: "Which servers to run on"

STEP 4: Ansible connects to each server via SSH
        Uses existing SSH (no agent needed!)
        Authenticates with your SSH key
        Opens secure connection

STEP 5: Ansible transfers task code to server
        Creates Python code that does the task
        Sends via SSH
        Executes on the server
        Server returns JSON result

STEP 6: Ansible evaluates results
        Check: Did it work?
        Check: Did it change anything?
        Check: Are there errors?

STEP 7: Ansible displays results
        Shows: "Server1: OK, Server2: OK"
        Shows: How long it took
        Shows: What changed

STEP 8: All done!
        All servers in identical state
        100% verified
        Full audit trail
```

### Why Agentless Is Better

**Agent-Based (Puppet, Chef):**
```
Server 1: Install agent → Keep running → Consume resources
Server 2: Install agent → Keep running → Consume resources
Server 3: Install agent → Keep running → Consume resources
...
Server 500: Install agent → Keep running → Consume resources

Problems:
- Agent bugs need fixing
- Agent versions to manage
- Agent uses CPU/memory
- Agent needs security updates
- Complex dependency management
```

**Agentless (Ansible):**
```
Ansible: Install once on control node
↓ Uses SSH (already exists on all Linux servers!)
Servers 1-500: Use SSH to connect
              No agent software needed
              No resource consumption
              No version management
              Simple!
```

### Key Principles

**1. Simplicity**
- Uses YAML (simple text format)
- No programming knowledge required
- Anyone can read and understand playbooks
- Short learning curve (hours, not weeks)

**2. Agentless**
- No software to install on managed servers
- Uses SSH (already standard on Linux)
- Lower security risk
- Easier to manage at scale

**3. Idempotency**
- Running playbook multiple times = same result
- Safe to run repeatedly
- No unexpected side effects
- Fix problems by re-running playbook

**4. No Proprietary Protocol**
- Uses SSH (open standard)
- Works with any Linux system
- No firewall rules needed
- Compatible everywhere

---

# SECTION 2: INVENTORY MANAGEMENT - COMPLETE EXPLANATION

## What is Inventory?

Inventory is a **database of servers** that tells Ansible:
1. Which servers exist
2. How to reach them
3. How to group them
4. What variables they need

### Why Inventory Matters

Without inventory:
- Ansible doesn't know which servers to manage
- Can't organize servers logically
- Can't share configuration
- Chaos!

With inventory:
- Central source of truth
- All servers defined in one place
- Easy to organize by environment
- Easy to share between teams

## Inventory Formats Explained

### INI Format (Simple)

```ini
# hosts.ini - Simple inventory

# Define a group
[webservers]
web1.example.com
web2.example.com
web3.example.com

# Another group
[databases]
db1.example.com
db2.example.com

# Host-specific variables (override per host)
[webservers]
web1.example.com  http_port=80   is_primary=true
web2.example.com  http_port=80   is_primary=false

# Group variables (apply to ALL servers in group)
[webservers:vars]
nginx_version=latest
ssl_enabled=true
backup_enabled=true

# Parent groups (groups of groups)
[production:children]
webservers
databases

# All servers get these variables
[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/ansible_key
```

**How INI Works:**
- `[groupname]` - Start a group definition
- `hostname` - Add server to group
- `var=value` - Set variable for this server
- `[groupname:vars]` - Variables for entire group
- `[parent:children]` - Parent group containing other groups

### YAML Format (Powerful)

```yaml
# hosts.yml - YAML inventory

all:                           # Start with 'all' (includes all servers)
  
  vars:                        # Variables for ALL servers
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/ansible_key
  
  children:                    # Sub-groups
    
    webservers:                # Group 1: Web Servers
      hosts:
        web1.example.com:
          http_port: 80
          is_primary: true
        web2.example.com:
          http_port: 80
          is_primary: false
      vars:                    # Variables for webservers group
        nginx_version: latest
        ssl_enabled: true
    
    databases:                 # Group 2: Databases
      hosts:
        db1.example.com:
        db2.example.com:
      vars:
        mysql_version: 8.0
        max_connections: 500
    
    production:                # Group 3: Production (parent group)
      children:
        - webservers
        - databases
```

**Why use YAML:**
- More flexible
- Better for complex structures
- Easier to organize large inventories
- Supports nested groups
- Better for automation teams

## Static vs Dynamic Inventory

### Static Inventory (You Write It)

```ini
# inventory.ini - You created this manually
[webservers]
web1.example.com
web2.example.com
```

**Good for:**
- Small deployments (10-50 servers)
- Stable infrastructure
- Simple setups

**Bad for:**
- Dynamic cloud environments
- Auto-scaling
- 100s of servers
- Constantly changing infrastructure

### Dynamic Inventory (Ansible Queries It)

```yaml
# aws_ec2.yml - Queries AWS automatically
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  instance-state-name: running
```

**How it works:**
1. When you run playbook, Ansible queries AWS API
2. Gets list of ALL running instances
3. Uses that as inventory (no manual updates!)
4. If servers created/destroyed, automatically reflects

**Good for:**
- Cloud environments (AWS, GCP, Azure)
- Auto-scaling groups
- Large deployments
- Constantly changing infrastructure
- Real-time inventory accuracy

**Real Example:**
```
Day 1: 100 servers running
       You run: ansible-playbook deploy.yml
       Ansible queries AWS → Finds 100 servers → Deploys to all

Day 2: Auto-scaling added 50 more servers
       You run: ansible-playbook deploy.yml
       Ansible queries AWS → Finds 150 servers → Deploys to all
       (No inventory file update needed!)

Day 3: Load dropped, auto-scaling removed 30 servers
       You run: ansible-playbook deploy.yml
       Ansible queries AWS → Finds 120 servers → Deploys to all
       (Still no manual updates!)
```

---

# SECTION 3: ANSIBLE CONFIGURATION - COMPLETE EXPLANATION

## What is ansible.cfg?

Configuration file that tells Ansible **how to behave**.

### Where Ansible Looks for ansible.cfg

Ansible checks in this order (uses FIRST one found):

```
1. ANSIBLE_CONFIG environment variable
   $ export ANSIBLE_CONFIG=/etc/ansible/custom.cfg
   
2. ./ansible.cfg (current directory)
   $ cd /home/user/myproject
   $ ls ansible.cfg  ← If exists here, use this!
   
3. ~/.ansible.cfg (home directory)
   $ cat ~/.ansible.cfg
   
4. /etc/ansible/ansible.cfg (system)
   $ cat /etc/ansible/ansible.cfg
```

Most common: Put ansible.cfg in your project directory

### Key Configuration Options Explained

#### [defaults] Section - Core Behavior

```ini
[defaults]

# INVENTORY - Where to find hosts
inventory = ./inventory/hosts.ini
# What it means: Look in ./inventory/hosts.ini for server list
# Without this: Ansible doesn't know which servers exist!

# REMOTE_USER - Who to log in as via SSH
remote_user = ubuntu
# What it means: When connecting, use 'ubuntu' user
# AWS Ubuntu: ubuntu
# AWS Amazon Linux: ec2-user
# Azure Linux: azureuser

# PRIVATE KEY - SSH authentication key
private_key_file = ~/.ssh/ansible_key
# What it means: Use ~/.ssh/ansible_key for SSH connections
# Must have proper permissions: chmod 600 ~/.ssh/ansible_key

# HOST KEY CHECKING - Verify server identity
host_key_checking = False
# What it means: Don't ask about SSH host key verification
# For automation: Set to False (can't interactively answer yes/no)
# For security: Set to True in production

# BECOME - Use sudo by default
become = yes
# What it means: Automatically use 'sudo' for tasks
# Many tasks need root (installing packages, modifying /etc/)

# BECOME METHOD - How to become root
become_method = sudo
# What it means: Use 'sudo' (vs 'su', 'doas', etc)

# BECOME USER - Which user to become
become_user = root
# What it means: Use 'sudo' to become 'root' user

# GATHER FACTS - Collect system information automatically
gather_facts = True
# What it means: Run 'setup' module automatically at start
# Makes available: {{ ansible_os_family }}, {{ ansible_processor_vcpus }}, etc
# Cost: ~5 seconds, worth it for conditionals and templates

# FACT CACHING - Cache facts for reuse
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400
# What it means: Cache facts for 24 hours
# Benefit: Subsequent runs skip fact gathering (faster)

# PARALLELIZATION - How many servers in parallel
forks = 5
# What it means: Connect to 5 servers simultaneously
# Default: 5 (slow)
# Recommended: 10-20 (good balance)
# Large scale: 30-50 (if control node powerful)

# DISPLAY OPTIONS - Control output
display_skipped_hosts = False  # Don't show skipped tasks
display_ok_hosts = True        # Show successful tasks
force_color = True             # Colored output
```

#### [ssh_connection] Section - SSH Settings

```ini
[ssh_connection]

# PIPELINING - Reduce SSH overhead
pipelining = True
# What it means: Execute tasks in pipeline (reduce round-trips)
# Benefit: Much faster execution (50%+ speed improvement)
# Required: 'requiretty' disabled in sudoers

# SSH ARGUMENTS - Extra SSH options
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
# What it means:
# - ControlMaster=auto: Share SSH connections
# - ControlPersist=60s: Keep connection alive for 60 seconds
# - StrictHostKeyChecking=no: Don't verify host keys

# CONNECTION TIMEOUT - How long to wait for SSH
timeout = 10
# What it means: If can't connect in 10 seconds, fail
# Default: 10 seconds (usually fine)
```

#### [privilege_escalation] Section - Sudo Settings

```ini
[privilege_escalation]

become = False              # Don't use sudo by default
become_method = sudo        # Use 'sudo' for escalation
become_user = root          # Become 'root' user
become_ask_pass = False     # Don't ask for password
```

---

# SECTION 4: PLAYBOOKS - COMPLETE EXPLANATION

## What is a Playbook?

A playbook is a **YAML file containing automation tasks**.

### Playbook Analogy

**Cooking Recipe:**
- Ingredients: What you need
- Instructions: What to do step-by-step
- Result: Finished dish

**Ansible Playbook:**
- Variables: What values to use
- Tasks: What commands to run step-by-step
- Result: Configured servers

### Complete Playbook Structure

```yaml
---
# Start of YAML file (required)

- name: Deploy Web Application
  # ^^ Play name - displayed when running
  
  hosts: webservers
  # ^^ Which servers to run on (from inventory)
  
  remote_user: ubuntu
  # ^^ SSH user to log in as
  
  become: yes
  # ^^ Use sudo for tasks
  
  gather_facts: yes
  # ^^ Automatically collect system info
  
  vars:
    # ^^ Variables defined here
    app_version: "2.5.0"
    app_port: 8080
    app_user: appuser
  
  pre_tasks:
    # ^^ Run BEFORE main tasks
    - name: Pre-flight checks
      assert:
        that:
          - ansible_memtotal_mb >= 4096
        fail_msg: "Need at least 4GB RAM"
  
  roles:
    # ^^ Include pre-organized task groups
    - common
    - webserver
    - monitoring
  
  tasks:
    # ^^ Main tasks (actual work)
    - name: Install nginx
      yum:
        name: nginx
        state: present
      notify: Restart nginx
    
    - name: Copy config
      copy:
        src: nginx.conf
        dest: /etc/nginx/nginx.conf
      notify: Restart nginx
  
  post_tasks:
    # ^^ Run AFTER main tasks
    - name: Health check
      uri:
        url: http://localhost:{{ app_port }}/health
        status_code: 200
      retries: 3
      delay: 5
  
  handlers:
    # ^^ Event-driven tasks (run when notified)
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
```

### Execution Order

```
1. Pre-flight validation
   (Check syntax, load files, validate)

2. Fact gathering
   (Collect system information - if gather_facts: yes)

3. Pre-tasks
   (Do checks, stop services, drain connections)

4. Roles
   (Run task sets from roles/)

5. Main tasks
   (The main work)

6. Handlers
   (Event-driven tasks - only if notified and task changed)

7. Post-tasks
   (Verify, health checks, restart monitoring)

8. Complete!
   (Display results and summary)
```

### Understanding Each Task Component

```yaml
- name: Install nginx
  # ^^ Description of what this task does
  # Shown during execution
  # Purely for humans to understand
  
  yum:
  # ^^ The MODULE - tool that performs the action
  # Examples: yum, apt, service, copy, template, user, group
  # Each module knows how to do specific thing
  # Module documentation explains all parameters
  
    name: nginx
    # ^^ Parameter 1: Which package to install
    # Different modules have different parameters
    # yum module needs: name (what to install)
    
    state: present
    # ^^ Parameter 2: Desired state
    # "present" = make sure nginx is installed
    # "absent" = make sure it's not installed
    # "latest" = install newest version
  
  notify: Restart nginx
  # ^^ Trigger handler if this task changes something
  # Only handler "Restart nginx" runs if nginx was installed
  # Handler doesn't run if nginx already present (no change)
  
  when: ansible_os_family == "RedHat"
  # ^^ Conditional execution
  # Only run this task if condition is true
  # If false: skip this task
  
  register: nginx_install
  # ^^ Save task result in variable 'nginx_install'
  # Can use result in later tasks
  # Example: {{ nginx_install.changed }} = true/false
  
  changed_when: false
  # ^^ Tell Ansible this task never changes anything
  # Even if something happens, don't mark as "changed"
  
  failed_when: false
  # ^^ Don't consider failure as failure
  # Even if it fails, continue playbook
  
  ignore_errors: yes
  # ^^ Don't stop if this task fails
  # Continue to next task regardless
  
  tags:
    - deploy
    - critical
  # ^^ Tags for selective execution
  # Run only tasks tagged: ansible-playbook deploy.yml --tags deploy
```

---

# SECTION 5: VARIABLES - COMPLETE EXPLANATION

## What are Variables?

Variables are **named containers that store values**.

### Why Variables Matter

WITHOUT variables:
```yaml
- name: Deploy app v2.5.0
  tasks:
    - get_url:
        url: https://releases.example.com/app-2.5.0.tar.gz
    - unarchive:
        src: /tmp/app-2.5.0.tar.gz
        dest: /opt/app-2.5.0
    - copy:
        src: config-2.5.0.conf
        dest: /etc/app.conf

# To deploy v2.6.0, must change "2.5.0" to "2.6.0" in 3 places!
# Easy to miss one! Creates inconsistency!
```

WITH variables:
```yaml
- name: Deploy app
  vars:
    app_version: "2.5.0"  # Define once
  tasks:
    - get_url:
        url: "https://releases.example.com/app-{{ app_version }}.tar.gz"
    - unarchive:
        src: "/tmp/app-{{ app_version }}.tar.gz"
        dest: "/opt/app-{{ app_version }}"
    - copy:
        src: "config-{{ app_version }}.conf"
        dest: /etc/app.conf

# To deploy v2.6.0, change ONE LINE!
# All three places update automatically!
```

## Variable Definition Methods (All 10)

### Method 1: Playbook vars Section

```yaml
- hosts: servers
  vars:
    app_name: myapp
    app_version: "2.5.0"
    debug_mode: false
    features:
      - auth
      - logging
      - monitoring
  tasks:
    - debug: msg="{{ app_name }} v{{ app_version }}"
```

When to use: Simple variables for one playbook

### Method 2: vars_files Section

```yaml
- hosts: servers
  vars_files:
    - vars/common.yml
    - vars/{{ environment }}.yml
    - vars/{{ ansible_os_family }}.yml
  tasks:
    - debug: msg="{{ variable_from_file }}"
```

Files loaded:
```yaml
# vars/common.yml
app_name: myapp
timeout: 30

# vars/production.yml
debug_mode: false
log_level: error

# vars/RedHat.yml
package_manager: yum
```

When to use: Organize variables into files by purpose

### Method 3: vars_prompt Section

```yaml
- hosts: servers
  vars_prompt:
    - name: deploy_version
      prompt: "Enter version to deploy (default: 2.5.0)"
      default: "2.5.0"
      private: no  # Show what I type
    
    - name: admin_password
      prompt: "Enter admin password"
      private: yes  # Don't show what I type (security)
  tasks:
    - debug: msg="Deploying {{ deploy_version }}"
```

When to use: Ask user for input during playbook run

### Method 4: register (Save Task Results)

```yaml
- hosts: servers
  tasks:
    - name: Check date
      shell: date
      register: current_date
      # ^^ Save result in 'current_date' variable
    
    - name: Display date
      debug:
        msg: "Current date: {{ current_date.stdout }}"
      # ^^ Use the saved result
      # current_date.stdout = output of date command
      # current_date.rc = return code
      # current_date.changed = did it change?
```

When to use: Use output from one task in another task

### Method 5: set_fact (Create Variables in Task)

```yaml
- hosts: servers
  vars:
    current_version: "2.5.0"
  tasks:
    - set_fact:
        next_version: "{{ (current_version | float) + 0.1 }}"
        # ^^ Create new variable from existing variable
        # next_version = 2.6
    
    - debug: msg="Next version: {{ next_version }}"
```

When to use: Calculate values during playbook execution

### Method 6: include_vars (Load From File)

```yaml
- hosts: servers
  tasks:
    - name: Load environment variables
      include_vars:
        file: vars/{{ environment }}.yml
        name: env_vars
        # ^^ Loads vars into 'env_vars' dictionary
    
    - debug: msg="{{ env_vars.database_host }}"
```

When to use: Dynamically load variables from files

### Method 7: Block-Level Variables

```yaml
- hosts: servers
  tasks:
    - block:
        - debug: msg="{{ block_variable }}"
      vars:
        block_variable: "Only available in this block"
        # ^^ Available only within this block
```

When to use: Variables needed only for group of tasks

### Method 8: Task-Level Variables

```yaml
- hosts: servers
  tasks:
    - debug:
        msg="{{ task_variable }}"
      vars:
        task_variable: "Only for this task"
        # ^^ Available only to this task
```

When to use: Variables needed for single task only

### Method 9: Extra Variables (Command Line)

```bash
# Pass variables from command line
$ ansible-playbook deploy.yml -e "app_version=2.6.0 debug=true"

# Or from file
$ ansible-playbook deploy.yml -e @vars.json

# Or from environment variable
$ export APP_VERSION=2.6.0
$ ansible-playbook deploy.yml -e "app_version=$APP_VERSION"
```

When to use: Override variables at runtime, most powerful method

### Method 10: Environment Variables

```yaml
- hosts: servers
  tasks:
    - name: Get API key from environment
      set_fact:
        api_key: "{{ lookup('env', 'API_KEY') }}"
        # ^^ Read from environment variable
    
    - debug: msg="API Key: {{ api_key }}"
```

When to use: Access environment variables in playbook

## Variable Precedence (Priority)

When variable defined in multiple places, which wins?

Priority (lowest to highest):
```
1. Role defaults (roles/myrole/defaults/main.yml)
2. Inventory variables (hosts.ini, group_vars, host_vars)
3. Playbook group_vars
4. Playbook host_vars
5. Role vars (roles/myrole/vars/main.yml)
6. Block variables
7. Task variables
8. Extra variables (HIGHEST - always wins!)
```

Example:
```
role defaults:      app_port = 1000
inventory:          app_port = 2000
playbook vars:      app_port = 3000
task vars:          app_port = 4000
extra vars (-e):    app_port = 5000

Result: app_port = 5000 (extra vars win!)
```

---

# SECTION 6: CONDITIONALS - COMPLETE EXPLANATION

## What is "when"?

The `when` directive is a **gatekeeper** - it controls whether a task runs.

```yaml
- name: Install nginx
  yum: name=nginx state=present
  when: ansible_os_family == "RedHat"
  # ^^ "Only run this if ansible_os_family equals RedHat"
```

How it works:
1. Ansible evaluates condition: `ansible_os_family == "RedHat"`
2. If TRUE → Run the task
3. If FALSE → Skip the task (no error)

## Common When Conditions

### Condition 1: Check Variable Equals Value

```yaml
when: ansible_os_family == "RedHat"
# Only run on RedHat/CentOS/Fedora systems

when: environment == "production"
# Only run in production environment

when: app_version | float >= 2.5
# Only if version is 2.5 or higher
```

### Condition 2: Check Variable is Defined

```yaml
when: api_key is defined
# Only run if api_key variable exists

when: debug_flag is not defined
# Only run if debug_flag doesn't exist
```

### Condition 3: Check Variable is Truthy/Falsy

```yaml
when: enable_feature | bool
# Only if enable_feature is true
# Converts "yes", "true", "1" to true

when: not skip_this | bool
# Only if skip_this is false
```

### Condition 4: Check String Contains Value

```yaml
when: "'web' in inventory_hostname"
# Only if hostname contains 'web'
# Example: web1.example.com → true
#          db1.example.com → false

when: "'production' in group_names"
# Only if server is in a group containing 'production'
```

### Condition 5: Check String Matches Regex

```yaml
when: inventory_hostname is regex('^web[0-9]+$')
# Only if hostname matches: web1, web2, web3, etc
# NOT web.example.com or database1

when: ansible_distribution is regex('(CentOS|RHEL)')
# Matches CentOS or RHEL
```

### Condition 6: Multiple Conditions (AND)

```yaml
when:
  - ansible_os_family == "RedHat"
  - ansible_distribution_major_version | int >= 7
  - app_version | float >= 2.0
# ALL conditions must be true
# If any is false, task is skipped
```

### Condition 7: Multiple Conditions (OR)

```yaml
when: ansible_distribution == "CentOS" or ansible_distribution == "RedHat"
# Either condition can be true
# If either is true, task runs

when: app_tier == "frontend" or app_tier == "web"
# Run if tier is frontend OR web
```

### Condition 8: Check Result From Previous Task

```yaml
- name: Check if service running
  shell: systemctl is-active nginx
  register: nginx_status
  changed_when: false

- name: Start nginx if not running
  service: name=nginx state=started
  when: nginx_status.rc != 0
  # rc=0 means service is running
  # rc!=0 means service is not running
```

### Condition 9: Check Host in Group

```yaml
when: inventory_hostname in groups['webservers']
# Only run on servers in webservers group

when: inventory_hostname not in groups['skip_deploy']
# Run on all servers EXCEPT those in skip_deploy group
```

### Condition 10: Check List Contains Item

```yaml
when: ansible_interfaces | length > 1
# Only if server has more than 1 network interface

when: required_packages | length > 0
# Only if required_packages list is not empty
```

---

# SECTION 7: LOOPS - COMPLETE EXPLANATION

## What is a Loop?

A loop **repeats a task multiple times** with different values.

### Why Loops Matter

WITHOUT loops (Tedious):
```yaml
- name: Create user alice
  user: name=alice state=present

- name: Create user bob
  user: name=bob state=present

- name: Create user charlie
  user: name=charlie state=present

# 3 tasks for 3 users
# If you need 100 users, 100 tasks!
# Code is repetitive and hard to maintain
```

WITH loops (Elegant):
```yaml
- name: Create users
  user:
    name: "{{ item }}"
    state: present
  loop:
    - alice
    - bob
    - charlie

# 1 task for 3 users
# If you need 100 users, still 1 task!
# Easy to maintain
```

## Loop Mechanisms Explained

### Basic Loop (Loop Over List)

```yaml
- name: Install packages
  yum:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - php
    - mysql
    - curl
    - git

# Execution:
# Iteration 1: item=nginx → yum install nginx
# Iteration 2: item=php → yum install php
# Iteration 3: item=mysql → yum install mysql
# Iteration 4: item=curl → yum install curl
# Iteration 5: item=git → yum install git
```

### Loop Over Dictionary

```yaml
- name: Create users with properties
  user:
    name: "{{ item.name }}"
    uid: "{{ item.uid }}"
    group: "{{ item.group }}"
  loop:
    - name: alice
      uid: 1001
      group: admin
    - name: bob
      uid: 1002
      group: users
    - name: charlie
      uid: 1003
      group: staff

# Iteration 1: item = {name: alice, uid: 1001, group: admin}
# Iteration 2: item = {name: bob, uid: 1002, group: users}
# Iteration 3: item = {name: charlie, uid: 1003, group: staff}
```

### Loop Over Range

```yaml
- name: Create 10 users
  user:
    name: "user{{ item }}"
    uid: "{{ 1000 + item }}"
  loop: "{{ range(1, 11) | list }}"

# Creates: user1 through user10
# user1 with uid 1001
# user2 with uid 1002
# etc
```

### Loop with Index

```yaml
- name: Display with index
  debug:
    msg: "Item {{ loop.index }}: {{ item }}"
  loop:
    - apple
    - banana
    - cherry

# Output:
# Item 1: apple
# Item 2: banana
# Item 3: cherry
```

### Loop with Label

```yaml
- name: Deploy to servers
  service:
    name: myapp
    state: restarted
  loop: "{{ groups['webservers'] }}"
  loop_control:
    label: "{{ item }}"
  # When many items in loop, label shows which item
  # Cleaner output
```

### Loop with Pause

```yaml
- name: Restart servers (one at a time)
  service:
    name: nginx
    state: restarted
  loop: "{{ groups['webservers'] }}"
  loop_control:
    pause: 30
  # Wait 30 seconds between iterations
  # Gives time for service to restart and stabilize
```

---

# SECTION 8: HANDLERS - COMPLETE EXPLANATION

## What are Handlers?

Handlers are **tasks that run when notified** - NOT automatically.

Think of it: Smoke alarm is a handler. Normally nothing happens. But if fire is detected, handler triggers (evacuation).

### Handler Usage Pattern

```yaml
- name: Deploy application
  hosts: servers
  tasks:
    
    - name: Copy config file
      copy:
        src: app.conf
        dest: /etc/app/app.conf
      notify: Restart application
      # ^^ If this task changes file, notify handler
    
    - name: Copy source code
      copy:
        src: app-{{ version }}.tar.gz
        dest: /opt/app.tar.gz
      notify: Restart application
      # ^^ If this task changes file, notify same handler

    # ... more tasks ...
  
  handlers:
    - name: Restart application
      service:
        name: myapp
        state: restarted
      listen: "Restart application"
      # ^^ This handler runs when notified
```

### Handler Execution Flow

```
SCENARIO: Config file changed

1. Task: Copy config file
   Old: version 1.0
   New: version 2.0
   Changed? YES → Notify handler
   
2. Task: Copy source code
   No changes
   Notify handler? NO
   
3. All tasks complete
   
4. Check: Any handlers to run? YES
   Handler: "Restart application" was notified
   
5. Run: Restart application service
   Service restarted with new config!

SCENARIO: Config file already same

1. Task: Copy config file
   Old: version 2.0
   New: version 2.0
   Changed? NO → Don't notify
   
2. Task: Copy source code
   No changes
   Notify handler? NO
   
3. All tasks complete
   
4. Check: Any handlers to run? NO
   (Handler was never notified)
   
5. Application NOT restarted
   (No need - nothing changed!)
```

### Why Handlers Matter

WITHOUT handlers:
```yaml
- name: Copy config
  copy: src=app.conf dest=/etc/app/app.conf

- name: Restart app
  service: name=app state=restarted

# Problem: App restarts EVERY TIME, even if config didn't change!
# Unnecessary downtime!
# Performance impact!
```

WITH handlers:
```yaml
- name: Copy config
  copy: src=app.conf dest=/etc/app/app.conf
  notify: Restart app

handlers:
  - name: Restart app
    service: name=app state=restarted

# Benefit: App only restarts if config ACTUALLY changed
# No unnecessary downtime!
# Better performance!
```

---

# SECTION 9: TEMPLATES - COMPLETE EXPLANATION

## What are Templates?

Templates are **files with placeholders** that get filled in with values.

### Template Example

**Template File (nginx.conf.j2):**
```
server {
    listen {{ listen_port }};
    server_name {{ server_hostname }};
    
    location / {
        proxy_pass http://{{ backend_server }}:{{ backend_port }};
    }
}
```

**Variables:**
```yaml
listen_port: 80
server_hostname: web1.example.com
backend_server: 10.0.1.100
backend_port: 8080
```

**Result (final file):**
```
server {
    listen 80;
    server_name web1.example.com;
    
    location / {
        proxy_pass http://10.0.1.100:8080;
    }
}
```

### Template vs Static File

**Static File (copy module):**
```yaml
- copy:
    src: app.conf
    dest: /etc/app/app.conf

# Copies exact same file to every server
# Can't customize per-server
```

**Template (template module):**
```yaml
- template:
    src: app.conf.j2
    dest: /etc/app/app.conf

# Fills in variables before copying
# Can customize per-server
# Each server gets different file (with different values)
```

### Why Templates Matter

**Scenario: Configure 100 load balancers**

WITHOUT templates:
```
Create 100 separate files:
  lb-config-1.conf  (for LB1)
  lb-config-2.conf  (for LB2)
  ...
  lb-config-100.conf (for LB100)

Each file slightly different (IP addresses, hostnames)
100 files to manage!
If need to change template, update 100 files!
Error prone!
```

WITH templates:
```
Create 1 template file: lb-config.conf.j2
With placeholders:
  {{ backend_ip }}
  {{ server_name }}
  {{ port }}

Use same template for all 100 servers
Each server provides its own values
Only 1 file to manage!
Easy to update!
```

### Jinja2 Syntax in Templates

```jinja2
{# This is a comment (not included in output) #}

{# Variable substitution #}
Server name: {{ server_name }}

{# Conditional #}
{% if environment == "production" %}
# This is production configuration
{% else %}
# This is development configuration
{% endif %}

{# Loop #}
{% for item in allowed_ips %}
allow {{ item }};
{% endfor %}

{# Filter (transform value) #}
Username: {{ username | lower }}     # Lowercase
Hostname: {{ hostname | upper }}     # Uppercase
Value: {{ price | round(2) }}        # Round to 2 decimals

{# Default value if undefined #}
Port: {{ custom_port | default(8080) }}

{# Test conditions #}
{% if variable is defined %}
Variable exists
{% endif %}
```

---

# SECTION 10: ROLES - COMPLETE EXPLANATION

## What are Roles?

Roles are **organized, reusable collections of tasks**.

Think of it: Recipe for Ansible. Just like cooking has recipes, Ansible has roles.

### Role Directory Structure

```
roles/
└── common/                 # Role name
    ├── README.md           # Documentation
    ├── defaults/           # Default variables
    │   └── main.yml        # Loaded first (lowest priority)
    ├── vars/               # Role variables
    │   └── main.yml        # Loaded after defaults
    ├── tasks/              # What tasks to do
    │   └── main.yml        # Entry point
    ├── handlers/           # Event-driven tasks
    │   └── main.yml
    ├── templates/          # Jinja2 templates
    │   └── config.j2
    ├── files/              # Static files
    │   └── app.tar.gz
    └── meta/               # Metadata
        └── main.yml        # Dependencies
```

### How Roles Work

**Playbook Using Roles:**
```yaml
- hosts: webservers
  roles:
    - common        # Run common role
    - webserver     # Run webserver role
    - monitoring    # Run monitoring role
```

**What Happens:**
```
1. Ansible finds roles/ directory
2. Finds role: common
   → Executes: roles/common/tasks/main.yml
   → All tasks in that file run
3. Finds role: webserver
   → Executes: roles/webserver/tasks/main.yml
4. Finds role: monitoring
   → Executes: roles/monitoring/tasks/main.yml
5. All tasks complete
```

### Why Roles Matter

WITHOUT roles:
```yaml
# Single giant playbook
- hosts: all
  tasks:
    - name: Install base packages
      yum: name=curl state=present
    
    - name: Install nginx
      yum: name=nginx state=present
    
    - name: Configure nginx
      copy: src=nginx.conf dest=/etc/nginx
    
    - name: Create app user
      user: name=appuser state=present
    
    # ... 100 more tasks ...
    # Hard to read
    # Hard to maintain
    # Hard to reuse
```

WITH roles:
```yaml
# Clean, organized playbook
- hosts: webservers
  roles:
    - common       # Setup base system
    - webserver    # Setup web server
    - app          # Deploy application

# Each role has tasks organized by purpose
# Easy to read
# Easy to maintain
# Easy to reuse on other playbooks
```

### Role with Variables

**Playbook:**
```yaml
- hosts: webservers
  roles:
    - role: nginx
      vars:
        nginx_port: 8080
        nginx_workers: 4
```

**Role uses variables:**
```yaml
# roles/nginx/tasks/main.yml
- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  vars:
    port: "{{ nginx_port }}"
    workers: "{{ nginx_workers }}"
```

### Role Dependencies

```yaml
# roles/webserver/meta/main.yml
dependencies:
  - common      # common role runs first
  - nginx       # then nginx
  - monitoring  # then monitoring
```

When you include webserver role:
```yaml
roles:
  - webserver
```

Ansible automatically runs:
1. common
2. nginx
3. monitoring
4. webserver

---

# SECTION 11: MODULE BASICS - COMPLETE EXPLANATION

## What is a Module?

A module is a **tool that performs a specific action**.

### Module Examples

```yaml
yum:          Install/remove packages (RedHat)
apt:          Install/remove packages (Debian)
service:      Start/stop/restart services
copy:         Copy files to remote servers
template:     Deploy template files
user:         Create/delete users
group:        Create/delete groups
file:         Manage files/directories
command:      Run shell commands
shell:        Run shell commands (with pipes, redirects)
mysql_db:     Manage MySQL databases
firewalld:    Manage firewall rules
ec2_instance: Create AWS EC2 instances
docker:       Manage Docker containers
```

Each module:
- Knows how to do one specific thing
- Has parameters you provide
- Returns results in JSON format
- Is idempotent (safe to run repeatedly)

### Understanding Module Parameters

```yaml
- name: Install nginx package
  yum:                      # Module: yum (package manager)
    name: nginx             # Parameter: which package
    state: present          # Parameter: desired state
    update_cache: yes       # Parameter: update package list first
  register: install_result  # Save result
```

**Parameter Explanation:**
- `name: nginx` → Install package called "nginx"
- `state: present` → Ensure nginx is installed
  - Options: present (installed), absent (not installed), latest (newest version)
- `update_cache: yes` → Run `yum update` first (get newest package list)
- `register: install_result` → Save result in variable for later use

### Module Result (JSON)

When module completes, Ansible receives JSON:

```json
{
  "changed": true,                    // Task changed something
  "name": "nginx",                    // Package name
  "state": "present",                 // Desired state
  "rc": 0,                           // Return code (0=success)
  "stdout": "Package installed...",  // Command output
  "stderr": ""                       // Errors (empty=no errors)
}
```

Ansible evaluates:
- `changed: true` → Task made a change
- `rc: 0` → Success (return code 0)
- If error, `failed: true` → Task failed

---

# SECTION 12: VAULT - SECRETS MANAGEMENT

## What is Vault?

Vault is **encryption for sensitive data**.

### Vault Use Cases

```
Store these ENCRYPTED in your Git repository:
✓ Database passwords
✓ API keys
✓ SSH keys
✓ Tokens
✓ Secrets

NOT encrypted (commit normally):
✓ Playbooks
✓ Tasks
✓ Configuration
✓ Everything else
```

### Using Vault

**Create Encrypted File:**
```bash
$ ansible-vault create secrets.yml
New Vault password: ****

# Opens editor
# Type your secrets:
db_password: "SuperSecret123"
api_key: "sk_live_abc123xyz"

# Save and close editor
# File is now ENCRYPTED
```

**Use in Playbook:**
```yaml
- hosts: servers
  vars_files:
    - secrets.yml  # Encrypted file
  tasks:
    - name: Configure database
      mysql_db:
        name: mydb
        password: "{{ db_password }}"  # Use secret variable
```

**Run Playbook:**
```bash
# With password prompt
$ ansible-playbook deploy.yml --ask-vault-pass
Vault password: ****

# Or with password file
$ ansible-playbook deploy.yml --vault-password-file ~/.vault_pass
```

---

# COMPLETE SUMMARY: YOU NOW HAVE

✅ Complete Ansible fundamentals explanation  
✅ Inventory management (static and dynamic)  
✅ Configuration (ansible.cfg)  
✅ Playbook structure (detailed)  
✅ Variables (all 10 methods)  
✅ Conditionals (when statements)  
✅ Loops (all types)  
✅ Handlers (event-driven)  
✅ Templates (Jinja2)  
✅ Roles (organization)  
✅ Modules (tools)  
✅ Vault (secrets)  

**EVERY TOPIC EXPLAINED IN COMPLETE DETAIL!**


---

# SECTION 13: ERROR HANDLING - COMPLETE EXPLANATION

## What is Error Handling?

Error handling controls **what happens when tasks fail**.

### Default Behavior (Without Error Handling)

```yaml
- hosts: servers
  tasks:
    - name: Task 1
      yum: name=nginx state=present

    - name: Task 2 (won't run if Task 1 fails)
      yum: name=php state=present

    - name: Task 3 (won't run if Task 1 or 2 fail)
      yum: name=mysql state=present
```

**If Task 1 fails:**
```
TASK [Task 1] failed!
ERROR: Task failed
→ Task 2 is NOT run
→ Task 3 is NOT run
→ Playbook stops
```

Result: Play stops immediately on first error!

### Technique 1: ignore_errors

```yaml
- name: This might fail but we don't care
  shell: /usr/bin/command_that_might_fail.sh
  ignore_errors: yes
  # Even if this fails, continue playbook
```

**Execution:**
```
If command fails:
→ error reported
→ but playbook CONTINUES
→ next task runs
```

Use when: Task failure is acceptable and doesn't block other tasks

### Technique 2: failed_when

```yaml
- name: Check system health
  shell: /opt/health_check.sh
  register: health
  failed_when: "'ERROR' in health.stdout"
  # Task fails only if 'ERROR' in output
  # Otherwise, task succeeds even if exit code is 1
```

**Execution:**
```
Command exits with code: 1 (normally fails)
But output: "All systems OK"
→ failed_when checks output for 'ERROR'
→ 'ERROR' not found
→ Task is marked as SUCCESS (even though exit code was 1)
→ Playbook continues
```

Use when: Exit code doesn't reflect real status

### Technique 3: changed_when

```yaml
- name: Check if restart needed
  shell: /opt/check_restart.sh
  register: restart_check
  changed_when: restart_check.stdout == "RESTART_NEEDED"
  # Only mark as "changed" if restart is needed
  # Otherwise mark as "ok" (no change)
```

**Execution:**
```
Script returns: "No restart needed"
→ changed_when evaluates condition
→ Condition false
→ Task marked as "ok" (no change)

Script returns: "RESTART_NEEDED"
→ changed_when evaluates condition
→ Condition true
→ Task marked as "changed"
→ Any handlers are notified
```

Use when: You want custom logic for what's considered a "change"

### Technique 4: Block-Rescue-Always (Try-Catch Pattern)

```yaml
- name: Deploy with error handling
  block:
    # TRY BLOCK - main code
    - name: Step 1: Stop service
      service: name=myapp state=stopped
    
    - name: Step 2: Backup database
      shell: mysqldump mydb > /backups/mydb.sql
    
    - name: Step 3: Deploy new code
      copy: src=app/ dest=/opt/app/
    
    - name: Step 4: Run migrations
      shell: /opt/app/migrate.sh
    
    - name: Step 5: Start service
      service: name=myapp state=started
  
  rescue:
    # RESCUE BLOCK - runs if ANY task in block fails
    - name: Rollback: Restore backup
      shell: mysql mydb < /backups/mydb.sql
    
    - name: Rollback: Restore old code
      shell: cp -r /opt/app.backup/* /opt/app/
    
    - name: Rollback: Start service
      service: name=myapp state=started
    
    - name: Alert: Send notification
      mail:
        subject: "Deployment failed and rolled back"
        body: "Manual intervention may be needed"
  
  always:
    # ALWAYS BLOCK - runs regardless of success/failure
    - name: Cleanup: Remove temp files
      file: path=/tmp/deploy_* state=absent
    
    - name: Cleanup: Remove backup
      file: path=/backups/mydb.sql state=absent
```

**Execution Flow:**

```
If all tasks in block succeed:
→ Block completes
→ Rescue does NOT run
→ Always runs (cleanup)
→ Playbook continues

If any task in block fails:
→ Remaining block tasks are skipped
→ Rescue runs (error recovery)
→ Always runs (cleanup)
→ If rescue fails:
  → Playbook fails
  → Always still runs
```

### Real Example: Rolling Back Bad Deployment

```yaml
- block:
    - name: Stop nginx (gracefully drain connections)
      service: name=nginx state=stopped

    - name: Backup old application
      command: cp -r /var/www/app /var/www/app.backup

    - name: Deploy new code
      unarchive:
        src: app-v2.5.0.tar.gz
        dest: /var/www/

    - name: Start nginx
      service: name=nginx state=started

    - name: Verify deployment (health check)
      uri:
        url: http://localhost/health
        status_code: 200
      register: health_check
      failed_when: health_check.status != 200

  rescue:
    - name: Alert team
      debug:
        msg: "CRITICAL: Deployment failed! Rolling back..."

    - name: Stop nginx
      service: name=nginx state=stopped
      ignore_errors: yes

    - name: Restore backup
      command: rm -rf /var/www/app && mv /var/www/app.backup /var/www/app

    - name: Start nginx with old code
      service: name=nginx state=started

    - name: Verify rollback
      uri:
        url: http://localhost/health
        status_code: 200

    - name: Send alert email
      mail:
        subject: "Deployment FAILED and ROLLED BACK"
        body: "New code had issues. Reverted to previous version."

  always:
    - name: Cleanup backup
      file: path=/var/www/app.backup state=absent
```

---

# SECTION 14: TAGS - COMPLETE EXPLANATION

## What are Tags?

Tags are **labels** that let you run only certain tasks.

### Tag Usage

```yaml
- hosts: servers
  tasks:
    - name: Install packages
      yum:
        name: nginx
        state: present
      tags:
        - install
        - packages

    - name: Configure nginx
      copy:
        src: nginx.conf
        dest: /etc/nginx/
      tags:
        - configure
        - web

    - name: Start service
      service:
        name: nginx
        state: started
      tags:
        - start
        - service
```

### Running with Tags

**Run only install tasks:**
```bash
$ ansible-playbook deploy.yml --tags install
# Only tasks with "install" tag run
# All other tasks skipped
```

**Run multiple tags:**
```bash
$ ansible-playbook deploy.yml --tags "install,configure"
# Tasks with "install" OR "configure" tag run
# Other tasks skipped
```

**Skip certain tags:**
```bash
$ ansible-playbook deploy.yml --skip-tags rollback
# All tasks run EXCEPT those with "rollback" tag
```

**List tasks and their tags:**
```bash
$ ansible-playbook deploy.yml --list-tasks
# Shows all tasks with their tags
```

### Special Tags

**"always" tag - always runs:**
```yaml
- name: Critical security task
  shell: iptables-save > /etc/iptables/rules.v4
  tags:
    - always
  # This task ALWAYS runs, even if other tags specified
```

**"never" tag - only runs if explicitly requested:**
```yaml
- name: Dangerous cleanup (only on demand)
  shell: rm -rf /opt/app/*
  tags:
    - never
    - dangerous_cleanup
  # This task NEVER runs unless you specifically request it
  # ansible-playbook deploy.yml --tags dangerous_cleanup
```

### Tag Organization Strategy

```yaml
tags:
  - install        # Task category: what it does
  - configure      # Task category: what it does
  - production     # Environment: where it runs
  - critical       # Importance: how critical is it
  - slow           # Performance: how long it takes
  - dangerous      # Risk: how risky is it
```

Real example:
```yaml
- name: Delete old logs
  shell: find /var/log/app -mtime +30 -delete
  tags:
    - maintenance
    - production
    - slow
    - dangerous

# Run only maintenance: ansible-playbook deploy.yml --tags maintenance
# Run only in production: ansible-playbook deploy.yml --tags production
# Skip slow tasks: ansible-playbook deploy.yml --skip-tags slow
# Run with caution: ansible-playbook deploy.yml --tags dangerous
```

---

# SECTION 15: WORKING WITH MULTIPLE SERVERS - COMPLETE EXPLANATION

## Understanding Parallelization

### Default Behavior (Parallel Execution)

```yaml
- hosts: webservers
  tasks:
    - name: Install nginx
      yum: name=nginx state=present
```

**Execution (with 5 servers):**

```
Timeline:

T+0s:  Ansible connects to Server 1, 2, 3, 4, 5 IN PARALLEL
       (All 5 at same time - very fast!)

T+1s:  Transfer nginx install module to all 5 servers
       (All 5 in parallel)

T+2s:  Execute on all 5 servers
       Server 1: installing...
       Server 2: installing...
       Server 3: installing...
       Server 4: installing...
       Server 5: installing...
       (All 5 at same time!)

T+5s:  All 5 servers done
       All 5 report back success

Total time: ~5 seconds for ALL 5 servers!
(vs 5 servers × 1 second each = 5 seconds anyway)
```

Parallelization controlled by `forks` in ansible.cfg:

```ini
[defaults]
forks = 5  # Default: 5 servers in parallel
```

Increase for faster execution:
```ini
forks = 20  # Handle 20 servers in parallel
# Faster but uses more resources
```

Decrease for lower resource usage:
```ini
forks = 2  # Handle 2 servers in parallel
# Slower but less resource-intensive
```

### Serial Execution (One at a Time)

```yaml
- hosts: webservers
  serial: 1  # Do one server at a time
  tasks:
    - name: Deploy app
      shell: /opt/deploy.sh
    
    - name: Health check
      uri:
        url: http://localhost/health
        status_code: 200
```

**Why use serial?**
- Rolling update (no downtime if all servers down)
- Canary deployment (test on one server first)
- Limited capacity (only one can restart at time)
- Risk mitigation (don't crash all at once)

**Execution (serial: 1 with 5 servers):**

```
T+0s:  Deploy to Server 1
T+10s: Health check Server 1 (passes)
       Deploy to Server 2
T+20s: Health check Server 2 (passes)
       Deploy to Server 3
T+30s: Health check Server 3 (passes)
       Deploy to Server 4
T+40s: Health check Server 4 (passes)
       Deploy to Server 5
T+50s: Health check Server 5 (passes)

Total: 50 seconds (vs 10 seconds with parallel)
But: Safe - each server verified before next
```

### Batch Execution (Groups of Servers)

```yaml
- hosts: webservers
  serial: 2  # Do 2 servers at a time
  tasks:
    - name: Deploy
      shell: /opt/deploy.sh
```

**Execution (serial: 2 with 5 servers):**

```
Batch 1: Deploy to Servers 1-2 (in parallel)
         T+0-10s

Batch 2: Deploy to Servers 3-4 (in parallel)
         T+10-20s

Batch 3: Deploy to Server 5
         T+20-30s

Total: 30 seconds (balance between speed and safety)
```

### Limiting Servers to Run On

```bash
# Run only on specific server
$ ansible-playbook deploy.yml -l web1.example.com

# Run only on servers in group
$ ansible-playbook deploy.yml -l webservers

# Run only on servers matching pattern
$ ansible-playbook deploy.yml -l "web[0-5].example.com"

# Exclude servers
$ ansible-playbook deploy.yml -l "webservers:!web1.example.com"
# Run on all webservers EXCEPT web1

# Multiple patterns (with comma)
$ ansible-playbook deploy.yml -l "web1.example.com,web2.example.com"
```

---

# SECTION 16: REAL-WORLD SCENARIO - COMPLETE WALK-THROUGH

## Scenario: Deploy Web Application to Production

### Step 1: Prepare Infrastructure

**inventory/production.yml:**
```yaml
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/ansible_key
  
  children:
    webservers:
      hosts:
        web1.prod.example.com:
          server_weight: 100
        web2.prod.example.com:
          server_weight: 50
        web3.prod.example.com:
          server_weight: 25
      vars:
        app_port: 8080
        ssl_enabled: true
```

### Step 2: Write Playbook

**deploy-app.yml:**
```yaml
---
- name: Deploy Web Application to Production
  hosts: webservers
  serial: 1  # One server at a time (rolling update)
  
  pre_tasks:
    - name: Pre-flight check
      assert:
        that:
          - ansible_memtotal_mb >= 4096
        fail_msg: "Server needs 4GB RAM"
    
    - name: Remove from load balancer
      uri:
        url: "http://load-balancer.internal/drain/{{ inventory_hostname }}"
        method: POST
      delegate_to: load_balancer.internal
  
  tasks:
    - name: Stop application
      service:
        name: myapp
        state: stopped
    
    - name: Backup current version
      shell: |
        cp -r /opt/app /opt/app.backup.{{ ansible_date_time.iso8601 }}
    
    - name: Deploy new version
      block:
        - name: Download application
          get_url:
            url: "https://releases.internal/app-{{ app_version }}.tar.gz"
            dest: /tmp/app.tar.gz

        - name: Extract
          unarchive:
            src: /tmp/app.tar.gz
            dest: /opt/
            remote_src: yes

        - name: Set permissions
          file:
            path: /opt/app
            owner: appuser
            group: appuser
            mode: '0755'
            recurse: yes

        - name: Copy config
          template:
            src: app-config.j2
            dest: /opt/app/config/production.conf
            owner: appuser
            group: appuser
            mode: '0640'

        - name: Run migrations
          shell: |
            /opt/app/bin/migrate.sh
          environment:
            APP_ENV: production
            DB_HOST: "{{ db_host }}"
            DB_NAME: "{{ db_name }}"
          become_user: appuser

      rescue:
        - name: Rollback on failure
          block:
            - name: Stop failed app
              service:
                name: myapp
                state: stopped
              ignore_errors: yes

            - name: Restore backup
              shell: |
                rm -rf /opt/app
                mv /opt/app.backup.* /opt/app

            - fail:
                msg: "Deployment failed. Rolled back to previous version."

    - name: Start application
      service:
        name: myapp
        state: started
        enabled: yes

  post_tasks:
    - name: Health check
      uri:
        url: "http://localhost:{{ app_port }}/health"
        status_code: 200
      register: health
      retries: 5
      delay: 10
      until: health.status == 200

    - name: Add back to load balancer
      uri:
        url: "http://load-balancer.internal/restore/{{ inventory_hostname }}"
        method: POST
      delegate_to: load-balancer.internal
    
    - name: Verify in load balancer
      uri:
        url: "http://load-balancer.internal/status/{{ inventory_hostname }}"
        status_code: 200
      retries: 3
      delay: 5
```

### Step 3: Run Deployment

```bash
# Run with verbose output
$ ansible-playbook deploy-app.yml \
    -i inventory/production.yml \
    -e "app_version=2.5.0" \
    -v

# Output:
PLAY [Deploy Web Application to Production] ***

TASK [Pre-flight check] ***
web1.prod.example.com | PASSED

TASK [Remove from load balancer] ***
web1.prod.example.com | CHANGED

TASK [Stop application] ***
web1.prod.example.com | CHANGED

TASK [Backup current version] ***
web1.prod.example.com | CHANGED

TASK [Deploy new version] ***
TASK [Download application] ***
web1.prod.example.com | CHANGED

TASK [Extract] ***
web1.prod.example.com | CHANGED

TASK [Set permissions] ***
web1.prod.example.com | CHANGED

TASK [Copy config] ***
web1.prod.example.com | CHANGED

TASK [Run migrations] ***
web1.prod.example.com | CHANGED

TASK [Start application] ***
web1.prod.example.com | CHANGED

TASK [Health check] ***
web1.prod.example.com | PASSED

TASK [Add back to load balancer] ***
web1.prod.example.com | CHANGED

TASK [Verify in load balancer] ***
web1.prod.example.com | PASSED

PLAY RECAP ***
web1.prod.example.com : ok=12 changed=10 unreachable=0 failed=0

(Repeats for web2, then web3)

Total time: ~5 minutes for all 3 servers
```

---

# SECTION 17: TROUBLESHOOTING - COMPLETE EXPLANATION

## Problem 1: SSH Connection Fails

**Error:**
```
FAILED! => {
  "msg": "Unable to connect to server1.example.com:22: [Errno -2] Name or service not known"
}
```

**Causes & Solutions:**

1. **Server doesn't exist / hostname wrong**
```bash
# Check if hostname is correct
$ ping server1.example.com
# If can't ping, wrong hostname or DNS issue
```

2. **SSH port wrong**
```ini
# ansible.cfg
[defaults]
remote_port = 2222  # Non-standard SSH port
```

3. **SSH key not found**
```bash
# Check if key exists
$ ls -la ~/.ssh/ansible_key
# If not exists, create it:
$ ssh-keygen -t rsa -f ~/.ssh/ansible_key

# Check permissions
$ ls -la ~/.ssh/ansible_key
# Should be: -rw------- (600)
# Fix if needed: chmod 600 ~/.ssh/ansible_key
```

4. **SSH key not authorized on server**
```bash
# Copy key to server
$ ssh-copy-id -i ~/.ssh/ansible_key.pub ubuntu@server1.example.com

# Verify
$ ssh -i ~/.ssh/ansible_key ubuntu@server1.example.com "echo OK"
# Should output: OK
```

## Problem 2: Authentication Fails

**Error:**
```
FAILED! => {
  "msg": "Permission denied (publickey)"
}
```

**Solutions:**

1. **Wrong SSH user**
```bash
# Verify correct user
$ ssh -i ~/.ssh/ansible_key ubuntu@server1.example.com  # Works?
$ ssh -i ~/.ssh/ansible_key ec2-user@server1.example.com  # Or this?

# Set correct user in ansible.cfg
[defaults]
remote_user = ubuntu
```

2. **Key not in authorized_keys**
```bash
# Check on server
$ cat ~/.ssh/authorized_keys
# Should contain your public key

# Add if missing
$ ssh-copy-id -i ~/.ssh/ansible_key.pub ubuntu@server1.example.com
```

## Problem 3: Task Fails

**Error:**
```
FAILED! => {
  "msg": "Failed to install package nginx: Permission denied"
}
```

**Solutions:**

1. **Need sudo but not configured**
```yaml
- name: Install nginx
  yum:
    name: nginx
    state: present
  become: yes  # Add this
```

Or in ansible.cfg:
```ini
[defaults]
become = yes
```

2. **Sudo requires password**
```bash
# Test
$ ssh -i ~/.ssh/ansible_key ubuntu@server1.example.com "sudo -n yum install nginx"

# If fails with "sudo requires password", set up passwordless sudo:
$ ssh ubuntu@server1.example.com
$ sudo visudo
# Add line:
ansible ALL=(ALL) NOPASSWD:ALL
```

## Problem 4: Variable Not Defined

**Error:**
```
FAILED! => {
  "msg": "The variable 'app_version' is undefined"
}
```

**Solutions:**

1. **Check variable is defined in inventory**
```bash
# Test variable
$ ansible webservers -i inventory.ini -m debug -a "var=app_version"
# Shows value if defined
# Shows "UNDEFINED VARIABLE" if not
```

2. **Check variable precedence**
```bash
# See all variables for a host
$ ansible web1.example.com -i inventory.ini -m setup | grep app_version

# Manual set via command line
$ ansible-playbook deploy.yml -e "app_version=2.5.0"
```

## Problem 5: Host Not Found

**Error:**
```
FAILED! => {
  "msg": "Unable to parse address"
}
```

**Solutions:**

1. **Check inventory file syntax**
```bash
# Validate inventory
$ ansible-inventory -i inventory.ini --list
# Shows all hosts

# If error, check YAML/INI syntax
```

2. **Check host group name**
```yaml
# In playbook, verify group name matches inventory
- hosts: webservers  # Must match [webservers] in inventory

# List available groups
$ ansible-inventory -i inventory.ini --graph
```

## Problem 6: Command Timeout

**Error:**
```
FAILED! => {
  "msg": "Timeout (12s) waiting for privilege escalation prompt"
}
```

**Solutions:**

1. **Increase timeout**
```ini
# ansible.cfg
[ssh_connection]
timeout = 30  # Increase from default 10
```

2. **Command is hanging**
```bash
# Test command manually
$ ssh ubuntu@server1.example.com "command"

# Add timeout to task
- name: Run command
  shell: command
  timeout: 60  # Task timeout in seconds
```

---

# SECTION 18: BEST PRACTICES - COMPLETE EXPLANATION

## 1. Always Make Tasks Idempotent

**Good (Idempotent):**
```yaml
- name: Install nginx
  yum:
    name: nginx
    state: present
# Safe to run 100 times - same result
```

**Bad (Not Idempotent):**
```yaml
- name: Install nginx
  shell: yum install -y nginx
# Might fail if already installed
# Unreliable
```

## 2. Use Meaningful Task Names

**Good:**
```yaml
- name: Install and configure nginx web server
  yum: name=nginx state=present
# Clearly explains what task does
```

**Bad:**
```yaml
- name: Task 1
  yum: name=nginx state=present
# Doesn't explain purpose
```

## 3. Organize with Roles

**Good:**
```
roles/
├── webserver/
│   ├── tasks/
│   ├── templates/
│   └── handlers/
└── database/
    ├── tasks/
    └── handlers/
```

**Bad:**
```yaml
# Single 1000-line playbook with everything
- hosts: all
  tasks:
    # 500 tasks here (hard to read!)
```

## 4. Separate Environments

**Good:**
```
inventory/
├── production.yml
├── staging.yml
└── development.yml

$ ansible-playbook deploy.yml -i inventory/production.yml
$ ansible-playbook deploy.yml -i inventory/staging.yml
$ ansible-playbook deploy.yml -i inventory/development.yml
```

**Bad:**
```
# Single inventory for all environments
# Risk of deploying to production accidentally!
```

## 5. Use Version Control

**Good:**
```bash
$ git init
$ git add playbooks/ inventory/ roles/
$ git commit -m "Deploy app v2.5.0"
$ git push origin main
# Full audit trail of all changes
```

**Bad:**
```bash
# Run playbooks from ad-hoc commands
# No version control
# Can't track who changed what
```

## 6. Secrets Management

**Good:**
```yaml
- hosts: servers
  vars_files:
    - vars/secrets.yml  # ENCRYPTED with Vault
  
  tasks:
    - mysql_db:
        password: "{{ db_password }}"
        # Password is encrypted, safe to commit
```

**Bad:**
```yaml
- hosts: servers
  tasks:
    - mysql_db:
        password: "SuperSecretPassword123"
        # Password in plain text - VERY INSECURE!
```

## 7. Test Before Production

**Good:**
```bash
# Test on one server first
$ ansible-playbook deploy.yml --limit web1.example.com --check

# Dry-run mode (doesn't actually change anything)
# Shows what WOULD be changed

# If looks good, run on production
$ ansible-playbook deploy.yml -i inventory/production.yml
```

**Bad:**
```bash
# Deploy directly to production without testing
# High risk of breaking things
```

---

# SECTION 19: COMPLETE QUICK REFERENCE

## Most Common Commands

```bash
# Test connectivity
$ ansible all -m ping

# Run command on all servers
$ ansible all -m shell -a "uptime"

# Copy file
$ ansible all -m copy -a "src=/tmp/file dest=/tmp/"

# Install package
$ ansible all -m yum -a "name=nginx state=present"

# Run playbook
$ ansible-playbook playbook.yml

# Run with inventory
$ ansible-playbook playbook.yml -i inventory.ini

# Run with extra variables
$ ansible-playbook playbook.yml -e "var1=value1"

# Dry-run mode (check what would change)
$ ansible-playbook playbook.yml --check

# Verbose output
$ ansible-playbook playbook.yml -v

# Very verbose (debug level)
$ ansible-playbook playbook.yml -vvv

# Limit to specific servers
$ ansible-playbook playbook.yml --limit webservers

# Run specific tags
$ ansible-playbook playbook.yml --tags deploy

# Skip specific tags
$ ansible-playbook playbook.yml --skip-tags rollback

# List all tasks
$ ansible-playbook playbook.yml --list-tasks

# List inventory
$ ansible-inventory -i inventory.ini --list

# Check playbook syntax
$ ansible-playbook playbook.yml --syntax-check
```

---

# CONCLUSION: YOU NOW HAVE COMPLETE UNDERSTANDING

This guide covers:

✅ **Ansible Fundamentals** - What it is and why it matters
✅ **Inventory Management** - How to define your servers
✅ **Ansible Configuration** - How to configure Ansible
✅ **Playbooks** - How to write automation
✅ **Variables** - How to use data
✅ **Conditionals** - How to make decisions
✅ **Loops** - How to repeat tasks
✅ **Handlers** - How to respond to events
✅ **Templates** - How to generate config files
✅ **Roles** - How to organize code
✅ **Modules** - How tasks actually work
✅ **Vault** - How to manage secrets
✅ **Error Handling** - How to handle failures
✅ **Tags** - How to select tasks
✅ **Working with Multiple Servers** - How to scale
✅ **Real-World Scenarios** - How it works in practice
✅ **Troubleshooting** - How to fix problems
✅ **Best Practices** - How to do it right
✅ **Quick Reference** - Common commands

**YOU ARE NOW READY TO USE ANSIBLE WITH COMPLETE CONFIDENCE!**


---

# SECTION 20: CI/CD WITH GITLAB AND ANSIBLE - COMPLETE EXPLANATION

## What is CI/CD?

**CI/CD = Continuous Integration / Continuous Deployment**

### Definition
- **CI (Continuous Integration):** Automatically test code changes
- **CD (Continuous Deployment):** Automatically deploy tested code to production

### Why CI/CD Matters

**Without CI/CD (Manual Process):**
```
Developer writes code
  ↓
Developer manually tests (30 minutes)
  ↓
Developer manually deploys (1 hour)
  ↓
Production is updated (1.5 hours later)
  ↓
If broken, manual rollback (30 minutes)

Total time: 2+ hours
Error rate: High (manual steps)
Reliability: Low (depends on person)
Frequency: Few times per day
```

**With CI/CD (Automated Process):**
```
Developer commits code to Git
  ↓
GitLab automatically tests (5 minutes)
  ↓
GitLab automatically deploys (5 minutes)
  ↓
Production updated (10 minutes)
  ↓
If broken, automatic rollback (1 minute)

Total time: 10 minutes
Error rate: Low (automated)
Reliability: High (consistent)
Frequency: Many times per day
```

### The Power of Automation

**Without Automation:**
- Deploy 2 times per week
- Takes 2 hours each
- Risk of bugs in production

**With Automation:**
- Deploy 20 times per day
- Takes 10 minutes each
- Bugs caught and rolled back automatically
- Smaller changes = easier to debug

---

## How GitLab CI/CD Works

### Overview

```
┌─────────────────────────────────────────────────┐
│             DEVELOPER WORKFLOW                   │
├─────────────────────────────────────────────────┤

1. Developer writes code
2. Developer commits: git push
3. GitLab receives commit
4. GitLab reads .gitlab-ci.yml
5. GitLab runs pipeline (tests, builds, deploys)
6. Pipeline succeeds/fails
7. Results shown to developer
8. If success: deployed to production
9. If failure: developer fixes and repeats
```

### Pipeline Stages

```
┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐
│ Stage1 │ → │ Stage2 │ → │ Stage3 │ → │ Stage4 │
│ Lint   │    │ Build  │    │ Test   │    │ Deploy │
└────────┘    └────────┘    └────────┘    └────────┘
   (5s)         (30s)         (60s)        (120s)

If any stage fails → Pipeline stops
If all pass → Continue to next stage
```

---

## GitLab CI/CD with Ansible - Complete Setup

### Step 1: Create .gitlab-ci.yml File

```yaml
# .gitlab-ci.yml - GitLab CI/CD configuration

# Define pipeline stages (order of execution)
stages:
  - lint
  - test
  - deploy_staging
  - deploy_production

# Variables available to all jobs
variables:
  ANSIBLE_HOST_KEY_CHECKING: "False"
  ANSIBLE_FORCE_COLOR: "True"

# ===== STAGE 1: LINT =====
# Check code quality before testing

lint_playbooks:
  stage: lint
  image: python:3.9
  before_script:
    - pip install ansible ansible-lint yamllint
  script:
    # Check Ansible syntax
    - ansible-lint
    
    # Check YAML syntax
    - yamllint .
    
    # Check all YAML files
    - find . -name "*.yml" -o -name "*.yaml" | xargs yamllint
  only:
    - merge_requests
    - main
    - develop
  tags:
    - docker

lint_syntax:
  stage: lint
  image: python:3.9
  before_script:
    - pip install ansible
  script:
    # Syntax check all playbooks
    - for file in playbooks/*.yml; do 
        echo "Checking $file..."; 
        ansible-playbook "$file" --syntax-check; 
      done
  only:
    - merge_requests
    - main
    - develop

# ===== STAGE 2: TEST =====
# Run tests on playbooks

test_with_molecule:
  stage: test
  image: python:3.9
  before_script:
    - pip install ansible molecule docker
  script:
    # Run Molecule tests (test Ansible code)
    - molecule test
  only:
    - merge_requests
    - main
  tags:
    - docker

test_playbook_check_mode:
  stage: test
  image: python:3.9
  before_script:
    - pip install ansible
    - mkdir -p ~/.ssh
    # Note: SSH key should be in GitLab CI/CD variables (not hardcoded!)
    - echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - ssh-keyscan -H example.com >> ~/.ssh/known_hosts
  script:
    # Test playbook in check mode (dry-run) on staging
    - ansible-playbook playbooks/deploy.yml 
        -i inventory/staging.ini 
        --check
        -v
  only:
    - merge_requests
  artifacts:
    reports:
      junit: test-results.xml
  tags:
    - docker

# ===== STAGE 3: DEPLOY STAGING =====
# Deploy to staging environment for testing

deploy_staging:
  stage: deploy_staging
  image: python:3.9
  environment:
    name: staging
    url: http://staging.example.com
  before_script:
    - pip install ansible
    - mkdir -p ~/.ssh
    # SSH key from GitLab CI/CD variables (STAGING_SSH_KEY)
    - echo "$STAGING_SSH_KEY" > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - ssh-keyscan -H staging1.example.com >> ~/.ssh/known_hosts
    - ssh-keyscan -H staging2.example.com >> ~/.ssh/known_hosts
  script:
    # First: Check mode (dry-run)
    - echo "=== Running in check mode (dry-run) ==="
    - ansible-playbook playbooks/deploy.yml 
        -i inventory/staging.ini 
        --check 
        -v
    
    # Second: Actual deployment
    - echo "=== Deploying to staging ==="
    - ansible-playbook playbooks/deploy.yml 
        -i inventory/staging.ini 
        -v
    
    # Third: Verify deployment
    - echo "=== Verifying deployment ==="
    - ansible-playbook playbooks/verify.yml 
        -i inventory/staging.ini 
        -v
  after_script:
    # Always run cleanup
    - echo "Deployment completed at $(date)"
  artifacts:
    paths:
      - deployment_log.txt
    expire_in: 1 week
  only:
    - develop
  when: manual  # Manually trigger (not automatic)
  tags:
    - docker

# ===== STAGE 4: DEPLOY PRODUCTION =====
# Deploy to production (final stage)

deploy_production:
  stage: deploy_production
  image: python:3.9
  environment:
    name: production
    url: http://example.com
    # Approval: Require manual approval before deploying
    deployment_tier: production
  before_script:
    - pip install ansible
    - mkdir -p ~/.ssh
    # SSH key from GitLab CI/CD variables (PRODUCTION_SSH_KEY)
    - echo "$PRODUCTION_SSH_KEY" > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    # Add all production servers to known_hosts
    - ssh-keyscan -H prod1.example.com >> ~/.ssh/known_hosts
    - ssh-keyscan -H prod2.example.com >> ~/.ssh/known_hosts
    - ssh-keyscan -H prod3.example.com >> ~/.ssh/known_hosts
  script:
    # Production deployment with extra safety
    
    # Step 1: Pre-deployment checks
    - echo "=== Pre-deployment checks ==="
    - ansible all -i inventory/production.ini -m ping
    
    # Step 2: Backup verification
    - echo "=== Verifying backups ==="
    - ansible-playbook playbooks/backup_verify.yml 
        -i inventory/production.ini 
        -v
    
    # Step 3: Dry-run
    - echo "=== Running in check mode ==="
    - ansible-playbook playbooks/deploy.yml 
        -i inventory/production.ini 
        --check 
        -v 
        -e "deployment_id=$CI_PIPELINE_ID"
    
    # Step 4: Actual deployment (rolling update)
    - echo "=== Deploying to production ==="
    - ansible-playbook playbooks/deploy.yml 
        -i inventory/production.ini 
        -v 
        -e "deployment_id=$CI_PIPELINE_ID"
    
    # Step 5: Health checks
    - echo "=== Running health checks ==="
    - ansible-playbook playbooks/health_check.yml 
        -i inventory/production.ini 
        -v
    
    # Step 6: Smoke tests
    - echo "=== Running smoke tests ==="
    - ansible-playbook playbooks/smoke_tests.yml 
        -i inventory/production.ini 
        -v
  after_script:
    # Notify deployment status
    - echo "Production deployment completed"
    - echo "Deployment ID: $CI_PIPELINE_ID"
  artifacts:
    paths:
      - logs/
    expire_in: 30 days
  only:
    - main  # Only deploy from main branch
  when: manual  # Must manually approve
  tags:
    - docker

# ===== ROLLBACK STAGE =====
# Emergency rollback if needed

rollback_production:
  stage: deploy_production
  image: python:3.9
  environment:
    name: production
  before_script:
    - pip install ansible
    - mkdir -p ~/.ssh
    - echo "$PRODUCTION_SSH_KEY" > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - ssh-keyscan -H prod1.example.com >> ~/.ssh/known_hosts
    - ssh-keyscan -H prod2.example.com >> ~/.ssh/known_hosts
    - ssh-keyscan -H prod3.example.com >> ~/.ssh/known_hosts
  script:
    - echo "=== EMERGENCY ROLLBACK ==="
    - ansible-playbook playbooks/rollback.yml 
        -i inventory/production.ini 
        -v 
        -e "rollback_reason='$CI_COMMIT_MESSAGE'"
    
    - echo "=== Verifying rollback ==="
    - ansible-playbook playbooks/verify.yml 
        -i inventory/production.ini 
        -v
  when: manual  # Only on manual request
  only:
    - main
  tags:
    - docker
```

### Step 2: Create Inventory Files

```ini
# inventory/staging.ini
[webservers]
staging1.example.com ansible_user=ubuntu
staging2.example.com ansible_user=ubuntu

[databases]
staging-db.example.com ansible_user=ubuntu

[all:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
environment=staging
log_level=debug
```

```ini
# inventory/production.ini
[webservers]
prod1.example.com ansible_user=ubuntu server_weight=100
prod2.example.com ansible_user=ubuntu server_weight=50
prod3.example.com ansible_user=ubuntu server_weight=25

[databases]
prod-db1.example.com ansible_user=ubuntu db_role=master
prod-db2.example.com ansible_user=ubuntu db_role=slave

[all:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
environment=production
log_level=error
```

### Step 3: Create Deployment Playbook

```yaml
# playbooks/deploy.yml
---
- name: Deploy Application
  hosts: webservers
  become: yes
  serial: 1  # One server at a time
  
  vars:
    app_version: "{{ lookup('env', 'CI_COMMIT_TAG') | default('latest') }}"
    deployment_id: "{{ deployment_id | default('unknown') }}"
  
  tasks:
    - name: Pre-deployment
      block:
        - name: Notify deployment started
          debug:
            msg: "Deployment {{ deployment_id }} started"
        
        - name: Stop monitoring
          service:
            name: monitoring-agent
            state: stopped
          ignore_errors: yes
        
        - name: Remove from load balancer
          uri:
            url: "http://lb.internal/drain/{{ inventory_hostname }}"
            method: POST
    
    - name: Deploy
      block:
        - name: Stop application
          service: name=myapp state=stopped
        
        - name: Backup current version
          shell: |
            cp -r /opt/app /opt/app.{{ deployment_id }}
        
        - name: Deploy new version
          copy:
            src: "app-{{ app_version }}.tar.gz"
            dest: /tmp/app.tar.gz
          register: deploy_copy
        
        - name: Extract application
          unarchive:
            src: /tmp/app.tar.gz
            dest: /opt/
            remote_src: yes
        
        - name: Set permissions
          file:
            path: /opt/app
            owner: appuser
            group: appuser
            mode: '0755'
            recurse: yes
        
        - name: Run migrations
          shell: /opt/app/migrate.sh
          environment:
            APP_ENV: "{{ environment }}"
        
        - name: Start application
          service: name=myapp state=started
      
      rescue:
        - name: Rollback on failure
          block:
            - name: Stop failed app
              service: name=myapp state=stopped
              ignore_errors: yes
            
            - name: Restore previous version
              shell: |
                rm -rf /opt/app
                mv /opt/app.{{ deployment_id }} /opt/app
            
            - name: Start app with old version
              service: name=myapp state=started
            
            - fail:
                msg: "Deployment failed and rolled back"
    
    - name: Post-deployment
      block:
        - name: Health check
          uri:
            url: "http://localhost:8080/health"
            status_code: 200
          retries: 5
          delay: 10
        
        - name: Add back to load balancer
          uri:
            url: "http://lb.internal/restore/{{ inventory_hostname }}"
            method: POST
        
        - name: Start monitoring
          service:
            name: monitoring-agent
            state: started
        
        - name: Notify deployment completed
          debug:
            msg: "Deployment {{ deployment_id }} completed successfully"
```

### Step 4: GitLab CI/CD Variables (Secrets)

In GitLab project settings → CI/CD → Variables, add:

```
STAGING_SSH_KEY = (paste staging private key)
PRODUCTION_SSH_KEY = (paste production private key)
ANSIBLE_VAULT_PASSWORD = (vault password)
```

**Important:** Mark as "Protected" and "Masked"

### Step 5: Complete Pipeline Flow

```yaml
Push to Git
  ↓
Lint Stage (5 minutes)
├─ ansible-lint
├─ yamllint
└─ syntax-check
  ↓ (if lint passes)
Test Stage (10 minutes)
├─ molecule test
└─ check-mode on staging
  ↓ (if tests pass)
Deploy Staging (15 minutes)
├─ Check mode
├─ Actual deploy
└─ Verification
  ↓ (manual trigger)
Deploy Production (20 minutes)
├─ Pre-checks
├─ Backup verify
├─ Check mode
├─ Deploy (rolling update)
├─ Health checks
└─ Smoke tests
  ↓
Complete! (50 minutes total)
```

---

# SECTION 21: ANSIBLE TOWER/AWX - COMPLETE EXPLANATION

## What is Ansible Tower/AWX?

### Definition
**Ansible Tower** = Enterprise-grade control center for Ansible
**AWX** = Open-source version of Ansible Tower

### Key Difference

```
Ansible CLI (Command Line):
- Playbooks stored in Git
- Run manually: ansible-playbook deploy.yml
- No GUI
- Limited history/logging
- No access control

Ansible Tower/AWX (Web Interface):
- Playbooks stored in Tower
- Run via Web UI or API
- Full GUI
- Complete audit trail
- Multi-user access control
- Job scheduling
- Notifications
- API for automation
```

### Why Tower/AWX Matters

**Without Tower (DIY Approach):**
```
15 people on team
Each runs Ansible manually from their laptop
  ↓
Who ran what? (No tracking)
Who has permission? (No control)
What changed? (No audit trail)
When did it run? (No schedule)
Did it succeed? (Check logs manually)
  ↓
Chaos!
```

**With Tower (Controlled Approach):**
```
15 people on team
All run Ansible through Tower UI
  ↓
Tower logs everything automatically
Tower controls who can do what
Tower tracks all changes
Tower can schedule jobs
Tower shows success/failure clearly
  ↓
Order!
```

---

## Installing Ansible Tower/AWX

### Option 1: Ansible Tower (Commercial)

**Steps:**
1. Download Tower installer
2. Untar and edit inventory
3. Run setup script
4. Enter license key
5. Access via web browser

### Option 2: AWX (Open Source) - Recommended

**Easiest: Using Docker**

```bash
# Step 1: Clone AWX repository
$ git clone https://github.com/ansible/awx.git
$ cd awx

# Step 2: Install Docker and Docker Compose
$ sudo yum install -y docker docker-compose

# Step 3: Start AWX
$ cd installer
$ ansible-playbook install.yml -i inventory

# Step 4: Wait for services to start
$ docker ps
# Should show: postgres, redis, awx_web, awx_task

# Step 5: Access AWX
# Open browser: http://localhost:80
# Username: admin
# Password: password (default)
```

**Using Ansible Playbook (More Control)**

```yaml
# Install AWX with Ansible

---
- name: Install AWX
  hosts: localhost
  gather_facts: yes
  
  vars:
    awx_version: "19.0.0"
    docker_compose_version: "1.29.2"
  
  tasks:
    - name: Install dependencies
      yum:
        name:
          - python3
          - python3-pip
          - docker
          - git
        state: present
    
    - name: Install docker-compose
      pip:
        name: docker-compose=={{ docker_compose_version }}
    
    - name: Clone AWX repository
      git:
        repo: https://github.com/ansible/awx.git
        dest: /opt/awx
        version: "{{ awx_version }}"
    
    - name: Run AWX installer
      shell: |
        cd /opt/awx/installer
        ansible-playbook install.yml -i inventory
```

---

## Configuring Ansible Tower/AWX

### Step 1: Add Credentials

**In Tower UI:**
1. Administration → Credentials
2. Create New:
   - Type: Machine
   - SSH Username: ubuntu
   - SSH Key Data: (paste private key)
   - Save

### Step 2: Create Inventory

**In Tower UI:**
1. Inventories → Create New
2. Name: Production
3. Add Hosts:
   - web1.example.com
   - web2.example.com
   - db1.example.com
4. Save

```yaml
# Or import from file
---
all:
  children:
    webservers:
      hosts:
        web1.example.com:
        web2.example.com:
    databases:
      hosts:
        db1.example.com:
```

### Step 3: Create Project

**In Tower UI:**
1. Projects → Create New
2. Name: MyProject
3. SCM Type: Git
4. SCM URL: https://github.com/myorg/ansible-playbooks.git
5. Update On Launch: Checked
6. Save

### Step 4: Create Job Template

**In Tower UI:**
1. Templates → Create New → Job Template
2. Name: Deploy Application
3. Job Type: Run
4. Inventory: Production
5. Project: MyProject
6. Playbook: playbooks/deploy.yml
7. Credentials: (select machine credentials)
8. Extra Variables:
   ```yaml
   app_version: "2.5.0"
   environment: production
   ```
9. Save

### Step 5: Create Workflow Template

**In Tower UI:**
1. Templates → Create New → Workflow Template
2. Name: Full Deployment Pipeline
3. Add Nodes:
   - Node 1: Lint Playbooks
   - Node 2: Test Playbooks
   - Node 3: Deploy to Staging
   - Node 4: Deploy to Production
4. Connect nodes (1→2→3→4)
5. Set success/failure handlers
6. Save

---

## Using Ansible Tower/AWX

### Running a Job via Web UI

```
1. Log in to Tower: http://localhost:80
2. Go to: Templates
3. Click: Deploy Application
4. Click: Launch
5. Enter variables if needed
6. Click: Launch Job

Result:
- Job starts
- Real-time console output shown
- Completion status displayed
- Full history saved
```

### Running a Job via API

```bash
# Get authentication token
$ curl -k -u admin:password \
  http://localhost/api/v2/authtoken/

# Result: {"token": "abc123xyz..."}

# Launch job template
$ curl -H "Authorization: Bearer abc123xyz..." \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"extra_vars": "{\"app_version\": \"2.5.0\"}"}' \
  http://localhost/api/v2/job_templates/1/launch/

# Result: {"job": 42}

# Check job status
$ curl -H "Authorization: Bearer abc123xyz..." \
  http://localhost/api/v2/jobs/42/
```

### Scheduling Jobs

**In Tower UI:**
1. Templates → Select Job Template
2. Schedules → Create New
3. Name: Daily Backup
4. Frequency: Daily
5. Time: 02:00 AM
6. Save

**Result:** Job automatically runs every day at 2 AM

---

## Tower/AWX Features

### 1. User Access Control

```
Admin:
├─ Can create/edit/delete everything
├─ Can manage users
└─ Can view all jobs

Team Lead:
├─ Can run specific jobs
├─ Can view job history
└─ Cannot modify playbooks

Developer:
├─ Can view but not run jobs
└─ Can view logs
```

### 2. Audit Logging

Tower automatically logs:
- Who ran the job
- When it ran
- What changed
- Success/failure
- Complete output

### 3. Notifications

When job completes, Tower can notify:
- Email
- Slack
- PagerDuty
- Custom webhooks

### 4. RBAC (Role-Based Access Control)

```
Define roles:
- Admin: Full access
- Operator: Run jobs
- Viewer: View only
- Developer: Edit playbooks only

Assign to users/teams
```

### 5. Job Templates with Surveys

```
Survey Question 1:
- Prompt: "Which environment?"
- Type: Multiple choice
- Choices: staging, production

Survey Question 2:
- Prompt: "App version?"
- Type: Text

Result: Non-technical users can run jobs safely
```

---

## Complete Tower/AWX Workflow Example

### Scenario: Deploy with Approval

```yaml
# workflow-deploy-with-approval.yaml

workflow_nodes:
  # Node 1: Auto-lint
  - id: 1
    job_template: "Lint Playbooks"
    success_nodes: [2]
    failure_nodes: [99]  # Go to failure node

  # Node 2: Auto-test
  - id: 2
    job_template: "Test Playbooks"
    success_nodes: [3]
    failure_nodes: [99]

  # Node 3: Approval node
  - id: 3
    type: approval
    description: "Approve production deployment"
    approvers: [admin_user, lead_user]
    success_nodes: [4]
    failure_nodes: [99]

  # Node 4: Deploy to production
  - id: 4
    job_template: "Deploy to Production"
    success_nodes: [5]
    failure_nodes: [98]  # Go to rollback

  # Node 5: Health check
  - id: 5
    job_template: "Health Check"
    success_nodes: []  # Done!
    failure_nodes: [98]

  # Node 98: Rollback (failure path)
  - id: 98
    job_template: "Rollback Production"

  # Node 99: Notification (failure notification)
  - id: 99
    type: notification
    message: "Deployment failed"
```

**Workflow Execution:**
```
1. Lint runs automatically
   ↓ if success
2. Test runs automatically
   ↓ if success
3. Wait for approval (human decision)
   ↓ if approved
4. Deploy runs automatically
   ↓ if success
5. Health check runs
   ↓ if success: Done!
   ↓ if failure: Rollback!
```

---

## Tower/AWX vs Manual Ansible

### Comparison Table

```
FEATURE                         MANUAL          TOWER/AWX
────────────────────────────────────────────────────────
Run playbooks                   CLI             Web UI or API
User authentication             None            Full RBAC
Job scheduling                  Cron            Built-in
Audit logging                   Manual/logs     Complete
Notifications                   Custom          Built-in
Inventory management            Files           Database
Access control                  SSH keys        RBAC roles
History/rollback                Manual          Automatic
API access                      No              Yes
Multi-user support              Complex         Native
Cost                            Free            $$
```

### When to Use Manual Ansible
- Small teams (< 5 people)
- Simple playbooks
- Occasional runs
- Learning Ansible
- No audit requirements

### When to Use Tower/AWX
- Medium+ teams (5+ people)
- Complex playbooks
- Frequent runs
- Audit trail needed
- Multiple environments
- API automation needed
- Non-technical users running jobs

---

## Complete Tower Setup Playbook

```yaml
---
- name: Complete AWX Setup with Playbooks
  hosts: awx_server
  become: yes
  
  vars:
    awx_admin_user: admin
    awx_admin_password: "{{ vault_awx_password }}"
    awx_host: "http://localhost"
  
  tasks:
    - name: Install AWX
      shell: |
        cd /opt/awx/installer
        ansible-playbook install.yml -i inventory
    
    - name: Wait for AWX to be ready
      uri:
        url: "{{ awx_host }}/api/v2/config/"
        status_code: 200
      register: result
      until: result.status == 200
      retries: 30
      delay: 10
    
    - name: Create machine credential
      awx.awx.credential:
        name: "SSH Key"
        credential_type: "Machine"
        organization: "Default"
        inputs:
          username: ubuntu
          ssh_key_data: "{{ lookup('file', '/path/to/ssh/key') }}"
        controller_host: "{{ awx_host }}"
        controller_username: "{{ awx_admin_user }}"
        controller_password: "{{ awx_admin_password }}"
    
    - name: Create inventory
      awx.awx.inventory:
        name: "Production"
        organization: "Default"
        controller_host: "{{ awx_host }}"
        controller_username: "{{ awx_admin_user }}"
        controller_password: "{{ awx_admin_password }}"
    
    - name: Add hosts to inventory
      awx.awx.host:
        name: "{{ item }}"
        inventory: "Production"
        controller_host: "{{ awx_host }}"
        controller_username: "{{ awx_admin_user }}"
        controller_password: "{{ awx_admin_password }}"
      loop:
        - web1.example.com
        - web2.example.com
        - db1.example.com
    
    - name: Create project
      awx.awx.project:
        name: "MyProject"
        organization: "Default"
        scm_type: "git"
        scm_url: "https://github.com/myorg/playbooks.git"
        scm_branch: "main"
        scm_update_on_launch: true
        controller_host: "{{ awx_host }}"
        controller_username: "{{ awx_admin_user }}"
        controller_password: "{{ awx_admin_password }}"
    
    - name: Create job template
      awx.awx.job_template:
        name: "Deploy Application"
        job_type: "run"
        organization: "Default"
        inventory: "Production"
        project: "MyProject"
        playbook: "playbooks/deploy.yml"
        credential: "SSH Key"
        extra_vars:
          app_version: "2.5.0"
          environment: "production"
        controller_host: "{{ awx_host }}"
        controller_username: "{{ awx_admin_user }}"
        controller_password: "{{ awx_admin_password }}"
    
    - name: Create workflow template
      awx.awx.workflow_template:
        name: "Deployment Pipeline"
        organization: "Default"
        controller_host: "{{ awx_host }}"
        controller_username: "{{ awx_admin_user }}"
        controller_password: "{{ awx_admin_password }}"
    
    - name: Create schedule
      awx.awx.schedule:
        name: "Daily Backup"
        rrule: "DTSTART:20230101T020000Z RRULE:FREQ=DAILY"
        unified_job_template: "Deploy Application"
        controller_host: "{{ awx_host }}"
        controller_username: "{{ awx_admin_user }}"
        controller_password: "{{ awx_admin_password }}"
```

---

## Conclusion: GitLab CI/CD + Ansible Tower

### Best Practice Architecture

```
┌─────────────────────────────────────────────────┐
│              DEVELOPER                           │
├─────────────────────────────────────────────────┤
│ Writes code → Commits to Git                    │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│           GITLAB CI/CD PIPELINE                 │
├─────────────────────────────────────────────────┤
│ 1. Lint (5 min)                                 │
│ 2. Test (10 min)                                │
│ 3. Deploy to Staging (15 min)                   │
│ 4. Approval Gate (manual)                       │
│ 5. Deploy to Production (20 min)                │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│         ANSIBLE TOWER COORDINATION              │
├─────────────────────────────────────────────────┤
│ Credentials stored securely                     │
│ Playbooks version controlled                    │
│ Job history and audit logs                      │
│ Notifications on completion                     │
│ Rollback capability                             │
└─────────────────────────────────────────────────┘
```

**You now have complete understanding of CI/CD with GitLab and Ansible Tower/AWX!**


---

# SECTION 22: ADVANCED JINJA2 FILTERS - COMPLETE REFERENCE

## What Are Jinja2 Filters?

Filters **transform values** during template rendering.

### Basic Filter Syntax

```jinja2
{{ value | filter_name }}
{{ value | filter_name(parameter) }}
{{ value | filter1 | filter2 }}  # Chain filters
```

---

## String Filters (Complete)

### Transformation Filters

```jinja2
{# Uppercase #}
{{ "hello" | upper }}
Result: "HELLO"

{# Lowercase #}
{{ "HELLO" | lower }}
Result: "hello"

{# Title case #}
{{ "hello world" | title }}
Result: "Hello World"

{# Capitalize first letter #}
{{ "hello world" | capitalize }}
Result: "Hello world"

{# Replace text #}
{{ "hello world" | replace("world", "ansible") }}
Result: "hello ansible"

{# Regular expression replace #}
{{ "hello123world456" | regex_replace('[0-9]', 'X') }}
Result: "helloXXXworldXXX"

{# Strip whitespace #}
{{ "  hello  " | trim }}
Result: "hello"

{# Split string #}
{{ "a,b,c" | split(",") }}
Result: ["a", "b", "c"]

{# Join list #}
{{ ["a", "b", "c"] | join(",") }}
Result: "a,b,c"

{# Indent text #}
{{ "hello\nworld" | indent(4) }}
Result:
    hello
    world

{# Wordwrap #}
{{ "This is a very long string" | wordwrap(10) }}
Result:
This is a
very long
string
```

### Search Filters

```jinja2
{# Check if contains #}
{% if "hello world" | regex_search("world") %}
  Found!
{% endif %}

{# Extract with regex #}
{{ "IP: 192.168.1.1" | regex_search('[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+') }}
Result: "192.168.1.1"

{# Find and replace #}
{{ "test@example.com" | regex_replace('@.*', '') }}
Result: "test"
```

---

## List Filters (Complete)

### Basic List Operations

```jinja2
{# First item #}
{{ [1, 2, 3] | first }}
Result: 1

{# Last item #}
{{ [1, 2, 3] | last }}
Result: 3

{# Length #}
{{ [1, 2, 3] | length }}
Result: 3

{# Join items #}
{{ [1, 2, 3] | join(",") }}
Result: "1,2,3"

{# Reverse #}
{{ [1, 2, 3] | reverse | list }}
Result: [3, 2, 1]

{# Sort #}
{{ [3, 1, 2] | sort }}
Result: [1, 2, 3]

{# Unique items #}
{{ [1, 2, 2, 3] | unique | list }}
Result: [1, 2, 3]

{# Flatten nested list #}
{{ [[1, 2], [3, 4]] | flatten }}
Result: [1, 2, 3, 4]

{# Select items matching condition #}
{{ [1, 2, 3, 4, 5] | select("odd") | list }}
Result: [1, 3, 5]

{# Reject items matching condition #}
{{ [1, 2, 3, 4, 5] | reject("even") | list }}
Result: [1, 3, 5]

{# Map (transform items) #}
{{ [1, 2, 3] | map("string") | list }}
Result: ["1", "2", "3"]

{# Sum #}
{{ [1, 2, 3] | sum }}
Result: 6

{# Max/Min #}
{{ [1, 2, 3] | max }}
Result: 3

{# Batch (group into chunks) #}
{{ [1, 2, 3, 4, 5] | batch(2) | list }}
Result: [[1, 2], [3, 4], [5]]
```

---

## Math Filters (Complete)

```jinja2
{# Absolute value #}
{{ -5 | abs }}
Result: 5

{# Round #}
{{ 3.14159 | round(2) }}
Result: 3.14

{# Round up #}
{{ 3.14159 | round(2, 'ceil') }}
Result: 3.15

{# Convert to int #}
{{ "42" | int }}
Result: 42

{# Convert to float #}
{{ "3.14" | float }}
Result: 3.14

{# Min/Max #}
{{ [1, 2, 3] | min }}
Result: 1
```

---

## Dictionary Filters (Complete)

```jinja2
{# Get keys #}
{{ {"a": 1, "b": 2} | dictsort }}
Result: [("a", 1), ("b", 2)]

{# Get items #}
{% for key, value in config.items() %}
  {{ key }}: {{ value }}
{% endfor %}

{# Default value if undefined #}
{{ undefined_variable | default("default_value") }}
Result: "default_value"

{# Require value (fail if undefined) #}
{{ required_variable | mandatory }}
# Fails if required_variable is undefined
```

---

## Advanced Filter Combinations

```jinja2
{# Chain multiple filters #}
{{ "hello WORLD" | lower | replace("world", "ansible") | title }}
Result: "Hello Ansible"

{# Conditional filter #}
{% if users | length > 0 %}
  Users: {{ users | join(", ") }}
{% else %}
  No users
{% endif %}

{# Complex transformation #}
{% set user_list = users | map(attribute='name') | list %}
{{ user_list | join(", ") }}

{# Nested filters #}
{{ config | to_json | regex_replace("password", "****") }}
```

---

# SECTION 23: ADVANCED PLAYBOOK PATTERNS - PRODUCTION EXAMPLES

## Pattern 1: Blue-Green Deployment

```yaml
---
- name: Blue-Green Deployment
  hosts: webservers
  serial: "{{ serial_count | default(5) }}"
  
  vars:
    # Which color is currently active
    active_color: "{{ current_active | default('blue') }}"
    # Which color to deploy to (opposite)
    deploy_color: "{{ 'green' if active_color == 'blue' else 'blue' }}"
  
  pre_tasks:
    - name: Get current active color
      shell: cat /opt/active_color.txt
      register: color_status
      changed_when: false
    
    - set_fact:
        active_color: "{{ color_status.stdout }}"
        deploy_color: "{{ 'green' if color_status.stdout == 'blue' else 'blue' }}"

  tasks:
    - name: Deploy to {{ deploy_color }} environment
      block:
        - name: Check {{ deploy_color }} environment
          service:
            name: "app-{{ deploy_color }}"
            state: started
        
        - name: Deploy application to {{ deploy_color }}
          copy:
            src: "app-{{ version }}.tar.gz"
            dest: "/opt/app-{{ deploy_color }}/"
        
        - name: Extract and configure
          shell: |
            cd /opt/app-{{ deploy_color }}
            tar -xzf app-{{ version }}.tar.gz
            ./configure.sh

        - name: Health check {{ deploy_color }}
          uri:
            url: "http://localhost:{{ deploy_color == 'blue' | ternary(8001, 8002) }}/health"
            status_code: 200
          retries: 5
          delay: 10

        - name: Run smoke tests on {{ deploy_color }}
          shell: /opt/smoke-tests-{{ deploy_color }}.sh

      rescue:
        - debug:
            msg: "Deployment to {{ deploy_color }} failed!"
        - fail:
            msg: "Cannot deploy to {{ deploy_color }}"

  post_tasks:
    - name: Switch load balancer to {{ deploy_color }}
      shell: |
        echo "{{ deploy_color }}" > /opt/active_color.txt
        systemctl reload load-balancer
    
    - name: Verify switch
      uri:
        url: http://load-balancer/status
        status_code: 200
      retries: 3
```

## Pattern 2: Canary Deployment

```yaml
---
- name: Canary Deployment Strategy
  hosts: webservers
  
  vars:
    # Deploy to 10% of servers first
    canary_batch_size: "{{ (groups['webservers'] | length * 0.1) | round(0, 'ceil') | int }}"
  
  tasks:
    - name: "Phase 1: Canary ({{ canary_batch_size }} servers)"
      block:
        - debug:
            msg: "Deploying to {{ canary_batch_size }} servers"
        
        - name: Deploy to canary servers
          include_role:
            name: deploy_app
          when: inventory_hostname in groups['webservers'][:canary_batch_size | int]
        
        - name: Monitor canary for errors
          uri:
            url: "http://{{ inventory_hostname }}/metrics"
            status_code: 200
          retries: 10
          delay: 30

      rescue:
        - debug:
            msg: "Canary deployment failed! Rolling back..."
        - include_role:
            name: rollback_app
        - fail:
            msg: "Canary deployment failed"

    - name: "Phase 2: Manual approval needed"
      pause:
        prompt: |
          Canary deployment successful!
          Check metrics and logs.
          Press enter to continue to full deployment
          or Ctrl+C to abort

    - name: "Phase 3: Full deployment (remaining servers)"
      block:
        - debug:
            msg: "Deploying to all remaining servers"
        
        - name: Deploy to remaining servers
          include_role:
            name: deploy_app
          when: inventory_hostname not in groups['webservers'][:canary_batch_size | int]
          serial: 5

      rescue:
        - debug:
            msg: "Full deployment failed! Rolling back all servers..."
        - include_role:
            name: rollback_app
        - fail:
            msg: "Full deployment failed"
```

## Pattern 3: Database Migration with Cutover

```yaml
---
- name: Database Migration with Zero Downtime
  hosts: localhost
  gather_facts: no
  
  vars:
    old_db: "mysql.old.internal"
    new_db: "mysql.new.internal"
    app_servers: "{{ groups['webservers'] }}"
  
  tasks:
    - name: Phase 1 - Pre-migration checks
      block:
        - name: Verify connectivity to both databases
          shell: |
            mysql -h {{ old_db }} -e "SELECT 1"
            mysql -h {{ new_db }} -e "SELECT 1"
        
        - name: Check replication lag
          shell: |
            mysql -h {{ new_db }} -e "SHOW SLAVE STATUS\G"
          register: replication_status

        - name: Verify replication lag < 1 second
          assert:
            that:
              - replication_status.stdout | regex_search("Seconds_Behind_Master: 0")
            fail_msg: "Replication lag too high!"

    - name: Phase 2 - Pre-cutover
      block:
        - name: Enable read-only mode on old database
          shell: |
            mysql -h {{ old_db }} -e "SET GLOBAL read_only = ON"
        
        - name: Wait for replication to catch up
          shell: |
            until mysql -h {{ new_db }} -e "SHOW SLAVE STATUS\G" | grep -q "Seconds_Behind_Master: 0"
            do
              echo "Waiting for replication..."
              sleep 1
            done
          timeout: 300

        - name: Stop application servers
          service:
            name: myapp
            state: stopped
          delegate_to: "{{ item }}"
          loop: "{{ app_servers }}"

      rescue:
        - name: Rollback - disable read-only
          shell: |
            mysql -h {{ old_db }} -e "SET GLOBAL read_only = OFF"
        - fail:
            msg: "Pre-cutover failed!"

    - name: Phase 3 - Cutover
      block:
        - name: Stop replication slave
          shell: |
            mysql -h {{ new_db }} -e "STOP SLAVE"
        
        - name: Point applications to new database
          copy:
            content: |
              database_host={{ new_db }}
              database_port=3306
            dest: /etc/myapp/db.conf
          delegate_to: "{{ item }}"
          loop: "{{ app_servers }}"
        
        - name: Start application servers with new database
          service:
            name: myapp
            state: started
          delegate_to: "{{ item }}"
          loop: "{{ app_servers }}"

        - name: Verify application health
          uri:
            url: "http://{{ item }}:8080/health"
            status_code: 200
          retries: 5
          delay: 10
          delegate_to: "{{ item }}"
          loop: "{{ app_servers }}"

      rescue:
        - name: Emergency rollback
          block:
            - name: Stop application servers
              service:
                name: myapp
                state: stopped
              delegate_to: "{{ item }}"
              loop: "{{ app_servers }}"
              ignore_errors: yes

            - name: Revert to old database
              copy:
                content: |
                  database_host={{ old_db }}
                  database_port=3306
                dest: /etc/myapp/db.conf
              delegate_to: "{{ item }}"
              loop: "{{ app_servers }}"

            - name: Disable read-only on old database
              shell: |
                mysql -h {{ old_db }} -e "SET GLOBAL read_only = OFF"

            - name: Restart applications
              service:
                name: myapp
                state: started
              delegate_to: "{{ item }}"
              loop: "{{ app_servers }}"

        - fail:
            msg: "Cutover failed! Rolled back to old database."

    - name: Phase 4 - Post-cutover validation
      block:
        - name: Run data consistency checks
          shell: |
            /opt/scripts/data_consistency_check.sh
          register: consistency_check

        - name: Verify no data loss
          assert:
            that:
              - "'SUCCESS' in consistency_check.stdout"
            fail_msg: "Data consistency check failed!"

        - name: Update DNS/load balancer
          shell: |
            dig {{ new_db }} +short | xargs -I {} aws route53 change-resource-record-sets \
              --hosted-zone-id Z123456 \
              --change-batch '{
                "Changes": [{
                  "Action": "UPSERT",
                  "ResourceRecordSet": {
                    "Name": "db.internal",
                    "Type": "A",
                    "TTL": 60,
                    "ResourceRecords": [{"Value": "{}"}]
                  }
                }]
              }'
```

---

# SECTION 24: PERFORMANCE OPTIMIZATION - DEEP DIVE

## Identifying Performance Bottlenecks

### Measure Execution Time

```yaml
---
- name: Performance benchmark
  hosts: servers
  gather_facts: yes
  
  pre_tasks:
    - name: Start timer
      set_fact:
        playbook_start_time: "{{ ansible_date_time.iso8601_micro }}"
  
  tasks:
    - name: Task with timer
      block:
        - name: Expensive operation
          shell: sleep 30
          register: task_result

        - name: Display duration
          debug:
            msg: "Task took {{ task_result.end | int - task_result.start | int }} seconds"
  
  post_tasks:
    - name: Display total playbook time
      debug:
        msg: |
          Playbook started: {{ playbook_start_time }}
          Playbook ended: {{ ansible_date_time.iso8601_micro }}
```

### Profile Plugin

```bash
# Add to ansible.cfg
[defaults]
callback_whitelist = profile_tasks

# Run playbook - shows task durations
$ ansible-playbook deploy.yml
...
Playback duration: 120.45 seconds
Task 1: 30.23 seconds
Task 2: 45.12 seconds
Task 3: 25.10 seconds
...
```

## Optimization Techniques

### 1. Enable Pipelining

```ini
# ansible.cfg
[ssh_connection]
pipelining = True

# Reduces SSH round-trips
# 50%+ speed improvement
# Requires: requiretty disabled in sudoers
```

### 2. Increase Forks

```ini
[defaults]
forks = 30  # Parallel connections

# Default: 5 (slow)
# Recommended: 10-20
# High performance: 30-50
```

### 3. Use Async for Long Operations

```yaml
- name: Long running backup (async)
  shell: /usr/bin/backup.sh
  async: 3600  # 1 hour timeout
  poll: 0      # Don't wait
  register: backup_job

# Do other work while backup runs

- name: Check backup status
  async_status:
    jid: "{{ backup_job.ansible_job_id }}"
  register: backup_result
  until: backup_result.finished
  retries: 120
  delay: 30
```

### 4. Disable Fact Gathering if Not Needed

```yaml
- hosts: servers
  gather_facts: no  # Skip if not using {{ ansible_* }}
  tasks:
    - debug: msg="Fact gathering disabled"
```

### 5. Use Fact Caching

```ini
[defaults]
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400  # 24 hours

# First run: Gather facts (slow)
# Second run: Use cached facts (fast!)
```

### 6. Batch Operations

```yaml
# BAD: Loop creates 5 tasks
- yum:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - php
    - mysql
    - curl
    - git

# GOOD: Single task installs all
- yum:
    name:
      - nginx
      - php
      - mysql
      - curl
      - git
    state: present
```

### 7. Use Block to Skip Conditionals

```yaml
# BAD: 100 tasks with same condition
- task: task1
  when: deployment_type == "production"
- task: task2
  when: deployment_type == "production"
... (100 more)

# GOOD: Block with condition
- block:
    - task: task1
    - task: task2
    ... (all tasks)
  when: deployment_type == "production"
```

---

# SECTION 25: ADVANCED SECURITY BEST PRACTICES

## 1. SSH Hardening

```ini
# ansible.cfg - Secure SSH
[ssh_connection]
ssh_args = -o ControlMaster=auto \
           -o ControlPersist=600s \
           -o StrictHostKeyChecking=accept-new \
           -o UserKnownHostsFile=/dev/null \
           -o IdentitiesOnly=yes \
           -o Compression=yes
```

## 2. Vault Best Practices

```bash
# GOOD: Separate vault file for each environment
vault/
├── development.yml
├── staging.yml
└── production.yml

# BAD: All secrets in one file

# Use vault ID for multiple passwords
$ ansible-playbook deploy.yml \
    --vault-id prod@prompt \
    --vault-id dev@dev_password_file
```

## 3. File Permissions

```yaml
- name: Secure sensitive files
  file:
    path: "{{ item }}"
    owner: root
    group: root
    mode: '0600'  # Only owner can read/write
  loop:
    - /etc/myapp/secrets.conf
    - /etc/myapp/ssh_keys
    - /etc/myapp/certificates
```

## 4. Audit Logging

```yaml
- name: Log all changes
  syslog:
    msg: "Ansible: {{ inventory_hostname }} - {{ ansible_task_name }}"
    facility: local2
    priority: info
```

## 5. Network Security

```yaml
- name: Restrict SSH access
  firewalld:
    port: 22/tcp
    source: 10.0.0.0/8  # Only internal network
    permanent: yes
    state: enabled
```

---

# SECTION 26: ANSIBLE COLLECTIONS DEEP DIVE

## What Are Collections?

Collections are **packages containing modules, roles, and plugins**.

### Using Collections

```bash
# Install from Galaxy
$ ansible-galaxy collection install community.general

# Install specific version
$ ansible-galaxy collection install community.general:3.0.0

# Install from requirements
$ ansible-galaxy collection install -r requirements.yml
```

### requirements.yml

```yaml
collections:
  # From Ansible Galaxy
  - name: community.general
    version: ">=5.0.0"
  
  # From GitHub
  - name: amazon.aws
    source: https://github.com/ansible-collections/amazon.aws.git
  
  # From local directory
  - name: my.custom
    source: file:///path/to/collection
```

### Using Collection Modules

```yaml
- hosts: servers
  tasks:
    # Full path (recommended)
    - amazon.aws.ec2_instance:
        name: my-instance
        instance_type: t3.micro
    
    # Short name (if collection imported)
    - collections:
        - community.general
      tasks:
        - timezone:
            name: America/New_York
```

---

# SECTION 27: REAL-WORLD COMPLETE SCENARIO

## Multi-Environment Deployment with Testing

```yaml
# Complete end-to-end deployment

---
- name: Complete deployment pipeline
  hosts: localhost
  gather_facts: no
  
  vars:
    environments:
      dev: development.yml
      staging: staging.yml
      prod: production.yml
    
    target_env: "{{ target_env | default('dev') }}"

  pre_tasks:
    - name: Validate environment
      assert:
        that:
          - target_env in environments
        fail_msg: "Invalid environment: {{ target_env }}"

  tasks:
    # === PHASE 1: Preparation ===
    - name: Phase 1 - Load inventory
      include_vars:
        file: "inventory/{{ environments[target_env] }}"
        name: env_vars

    - name: Phase 1 - Load secrets
      include_vars:
        file: "vault/{{ target_env }}.yml"
        name: secrets
      no_log: yes

    # === PHASE 2: Pre-deployment ===
    - name: Phase 2 - Connectivity check
      ping:
        data: "test"
      delegate_to: "{{ item }}"
      loop: "{{ env_vars.servers }}"
      register: ping_result

    - name: Phase 2 - Verify all servers reachable
      assert:
        that:
          - ping_result is not failed
        fail_msg: "Some servers unreachable!"

    # === PHASE 3: Deployment ===
    - name: Phase 3 - Deploy to {{ target_env }}
      include_role:
        name: deploy
      vars:
        deploy_env: "{{ target_env }}"
        deploy_vars: "{{ env_vars }}"
        deploy_secrets: "{{ secrets }}"

    # === PHASE 4: Validation ===
    - name: Phase 4 - Health checks
      uri:
        url: "http://{{ item }}/health"
        status_code: 200
      loop: "{{ env_vars.servers }}"
      retries: 5
      delay: 10

    - name: Phase 4 - Smoke tests
      shell: |
        /opt/smoke-tests.sh {{ target_env }}
      register: smoke_tests

    - name: Phase 4 - Verify no errors
      assert:
        that:
          - "'FAILED' not in smoke_tests.stdout"
        fail_msg: "Smoke tests failed!"

    # === PHASE 5: Post-deployment ===
    - name: Phase 5 - Update monitoring
      shell: |
        echo "{{ target_env }}: deployed" > /var/run/deployment_status
    
    - name: Phase 5 - Send notification
      mail:
        host: smtp.example.com
        subject: "Deployment successful: {{ target_env }}"
        body: |
          Environment: {{ target_env }}
          Deployed at: {{ ansible_date_time.iso8601 }}
          Status: SUCCESS
```

---

## FINAL SUMMARY: COMPLETE ANSIBLE MASTERY

**You now have comprehensive knowledge of:**

✅ Ansible Fundamentals (Why and How)
✅ Inventory Management (Static & Dynamic)
✅ Configuration (ansible.cfg)
✅ Playbooks (Complete structure)
✅ Variables (All 10 methods)
✅ Conditionals (When statements)
✅ Loops (All types)
✅ Handlers (Event-driven)
✅ Templates (Jinja2)
✅ Roles (Organization)
✅ Modules (75+ covered)
✅ Vault (Secrets)
✅ Error Handling (Complete)
✅ Tags (Selective execution)
✅ Multiple Servers (Scaling)
✅ Real-World Scenarios (Complete)
✅ Troubleshooting (20+ solutions)
✅ Best Practices (Production patterns)
✅ GitLab CI/CD Integration
✅ Ansible Tower/AWX
✅ Advanced Jinja2 Filters
✅ Advanced Playbook Patterns
✅ Performance Optimization
✅ Security Best Practices
✅ Collections (Modern Ansible)
✅ Complete End-to-End Examples

**Total Content:** 3,960+ lines of exhaustive, detailed explanations!

**You are now EXPERT-LEVEL ready with Ansible!**


---

# SECTION 28: MOLECULE TESTING FRAMEWORK - COMPLETE GUIDE

## What is Molecule?

Molecule is a **testing framework for Ansible roles**.

### Why Testing Matters

```
WITHOUT Testing:
- Deploy role to production
  ↓
- Something breaks
  ↓
- Customers see errors
  ↓
- Emergency rollback
  ↓
- Embarrassing!

WITH Testing (Molecule):
- Test role before deployment
  ↓
- Catch bugs in staging
  ↓
- Deploy to production confident
  ↓
- Everything works
  ↓
- Happy customers!
```

## Installing Molecule

```bash
# Install Molecule
$ pip install molecule

# Install Docker driver (recommended)
$ pip install molecule-docker

# Verify installation
$ molecule --version
```

## Molecule Structure

```
roles/webserver/
├── molecule/
│   ├── default/
│   │   ├── molecule.yml      # Test config
│   │   ├── playbook.yml      # Test playbook
│   │   ├── converge.yml      # Apply role
│   │   ├── verify.yml        # Verify role worked
│   │   └── prepare.yml       # Setup test environment
│   └── ubuntu/               # Alternative scenario
│       ├── molecule.yml
│       └── converge.yml
├── tasks/
├── handlers/
└── templates/
```

## Complete molecule.yml

```yaml
# molecule/default/molecule.yml

---
driver:
  # Use Docker for testing
  name: docker

platforms:
  # Test on multiple OS versions
  - name: ubuntu-20
    image: docker.io/pycontribs/ubuntu:20.04
    pre_build_image: yes
    command: /lib/systemd/systemd-cgroups-agent
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    tmpfs:
      - /run
      - /tmp
    networks:
      - name: test
  
  - name: centos-8
    image: docker.io/pycontribs/centos:8
    pre_build_image: yes
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    tmpfs:
      - /run
      - /tmp

provisioner:
  # Run tests using Ansible
  name: ansible
  lint:
    # Lint playbooks and YAML
    name: ansible-lint
  inventory:
    host_vars:
      ubuntu-20:
        nginx_port: 8080
        nginx_workers: 2
      centos-8:
        nginx_port: 8080
        nginx_workers: 4

scenario:
  # Sequence of operations
  test_sequence:
    - lint
    - syntax
    - create
    - prepare
    - converge
    - idempotence
    - side_effect
    - verify
    - cleanup
    - destroy
```

## Complete Test Playbooks

```yaml
# molecule/default/converge.yml
# Apply the role being tested

---
- name: Test role
  hosts: all
  gather_facts: yes
  
  tasks:
    - name: Include webserver role
      include_role:
        name: webserver
      vars:
        nginx_port: 8080
        nginx_workers: 4
```

```yaml
# molecule/default/verify.yml
# Verify role worked correctly

---
- name: Verify webserver role
  hosts: all
  gather_facts: yes
  
  tasks:
    - name: Check nginx is installed
      package_facts:
        manager: auto
      register: pkg_facts
    
    - name: Verify nginx package
      assert:
        that:
          - "'nginx' in pkg_facts.ansible_facts.packages"
        fail_msg: "nginx not installed!"
    
    - name: Check nginx is running
      service_facts:
      register: services
    
    - name: Verify service status
      assert:
        that:
          - services.ansible_facts.services['nginx.service'].state == 'running'
        fail_msg: "nginx not running!"
    
    - name: Health check
      uri:
        url: "http://localhost:{{ nginx_port }}/health"
        status_code: 200
      retries: 3
      delay: 5
```

## Running Molecule Tests

```bash
# Run all tests (create, converge, verify, destroy)
$ molecule test

# Create test environment only
$ molecule create

# Run tests without cleanup
$ molecule converge

# Verify (run verify.yml)
$ molecule verify

# Cleanup/destroy containers
$ molecule destroy

# Test idempotence (run twice, should be identical)
$ molecule idempotence

# Test with specific scenario
$ molecule test -s ubuntu

# Debug/troubleshoot (keep container running)
$ molecule converge
$ molecule login  # SSH into container
$ molecule destroy  # Cleanup when done
```

## CI/CD Integration

```yaml
# .gitlab-ci.yml integration

test_with_molecule:
  stage: test
  image: python:3.9
  before_script:
    - pip install ansible molecule molecule-docker docker
    - docker --version
  script:
    - cd roles/webserver
    - molecule test
  artifacts:
    paths:
      - roles/webserver/molecule/
    expire_in: 1 week
  only:
    - merge_requests
```

---

# SECTION 29: MULTI-CLOUD DEPLOYMENT - AWS, GCP, AZURE

## AWS Deployment Example

```yaml
---
- name: Deploy to AWS
  hosts: localhost
  gather_facts: no
  
  tasks:
    # Create VPC
    - name: Create VPC
      amazon.aws.ec2_vpc_net:
        name: production-vpc
        cidr_block: 10.0.0.0/16
        region: us-east-1
      register: vpc
    
    # Create subnet
    - name: Create subnet
      amazon.aws.ec2_vpc_subnet:
        vpc_id: "{{ vpc.vpc.id }}"
        cidr: 10.0.1.0/24
        region: us-east-1
      register: subnet
    
    # Launch EC2 instances
    - name: Launch EC2 instances
      amazon.aws.ec2_instance:
        key_name: ansible-key
        instance_type: t3.micro
        image_id: ami-0c55b159cbfafe1f0
        wait: yes
        count: 3
        tags:
          Name: "webserver-{{ item }}"
          Environment: production
      loop: "{{ range(1, 4) | list }}"
      register: ec2_instances
    
    # Add to inventory
    - name: Add instances to inventory
      add_host:
        name: "{{ item.instances[0].public_ip_address }}"
        groups: aws_webservers
        ansible_user: ec2-user
      loop: "{{ ec2_instances.results }}"
    
    # Wait for SSH
    - name: Wait for SSH
      wait_for:
        host: "{{ item.instances[0].public_ip_address }}"
        port: 22
        delay: 10
        timeout: 300
      loop: "{{ ec2_instances.results }}"

# Deploy to newly created instances
- name: Configure AWS instances
  hosts: aws_webservers
  become: yes
  
  tasks:
    - name: Install nginx
      yum:
        name: nginx
        state: present
    
    - name: Start nginx
      service:
        name: nginx
        state: started
```

## GCP Deployment Example

```yaml
---
- name: Deploy to GCP
  hosts: localhost
  gather_facts: no
  
  vars:
    gcp_project: my-project
    gcp_zone: us-central1-a
  
  tasks:
    # Create firewall rule
    - name: Create firewall rule
      google.cloud.gcp_compute_firewall:
        name: allow-http
        network: default
        rules:
          - action: ALLOW
            priority: 1000
            source_ranges: ['0.0.0.0/0']
            allowed:
              - IPProtocol: tcp
                ports: ['80', '443']
        project: "{{ gcp_project }}"
        auth_kind: serviceaccount
        service_account_file: /path/to/service-account-key.json
        state: present
    
    # Create instance template
    - name: Create instance template
      google.cloud.gcp_compute_instance_template:
        name: webserver-template
        properties:
          machine_type: n1-standard-1
          disks:
            - auto_delete: yes
              boot: yes
              source_image: projects/debian-cloud/global/images/debian-10
          network_interfaces:
            - network: default
              access_configs:
                - name: External NAT
        project: "{{ gcp_project }}"
        auth_kind: serviceaccount
        service_account_file: /path/to/service-account-key.json
    
    # Create instance group
    - name: Create instance group
      google.cloud.gcp_compute_instance_group_manager:
        name: webserver-group
        base_instance_name: webserver
        instance_template: webserver-template
        target_size: 3
        zone: "{{ gcp_zone }}"
        project: "{{ gcp_project }}"
        auth_kind: serviceaccount
        service_account_file: /path/to/service-account-key.json
```

## Azure Deployment Example

```yaml
---
- name: Deploy to Azure
  hosts: localhost
  gather_facts: no
  
  vars:
    azure_resource_group: production-rg
    azure_region: eastus
  
  tasks:
    # Create resource group
    - name: Create resource group
      azure.azcollection.azure_rm_resourcegroup:
        name: "{{ azure_resource_group }}"
        location: "{{ azure_region }}"
    
    # Create virtual network
    - name: Create virtual network
      azure.azcollection.azure_rm_virtualnetwork:
        resource_group: "{{ azure_resource_group }}"
        name: production-vnet
        address_prefixes: "10.0.0.0/16"
    
    # Create subnet
    - name: Create subnet
      azure.azcollection.azure_rm_subnet:
        resource_group: "{{ azure_resource_group }}"
        virtual_network_name: production-vnet
        name: production-subnet
        address_prefix: "10.0.1.0/24"
    
    # Create VMs
    - name: Create Azure VMs
      azure.azcollection.azure_rm_virtualmachine:
        resource_group: "{{ azure_resource_group }}"
        name: "webserver-{{ item }}"
        vm_size: Standard_B1s
        admin_username: azureuser
        ssh_public_keys:
          - path: /home/azureuser/.ssh/authorized_keys
            key_data: "{{ lookup('file', '/path/to/public/key') }}"
        network_interfaces: production-nic
        image:
          offer: UbuntuServer
          publisher: Canonical
          sku: "18.04-LTS"
          version: latest
      loop: "{{ range(1, 4) | list }}"
```

---

# SECTION 30: PRODUCTION DEPLOYMENT CHECKLIST

## Pre-Deployment Checklist

```yaml
---
- name: Pre-deployment validation
  hosts: localhost
  gather_facts: no
  
  vars:
    checklist:
      - "Playbook syntax verified"
      - "All variables defined"
      - "Backup created"
      - "Rollback plan documented"
      - "Team notified"
      - "Maintenance window scheduled"
      - "Monitoring configured"
  
  tasks:
    - name: Verify playbook syntax
      command: "ansible-playbook playbooks/deploy.yml --syntax-check"
    
    - name: Verify all variables
      assert:
        that:
          - required_variable is defined
          - app_version is defined
          - deployment_env is defined
        fail_msg: "Required variables not set!"
    
    - name: Backup before deployment
      shell: |
        mysqldump mydb > /backups/mydb.$(date +%Y%m%d_%H%M%S).sql
    
    - name: Verify connectivity
      ping:
      delegate_to: "{{ item }}"
      loop: "{{ groups['webservers'] }}"
    
    - name: Display checklist
      debug:
        msg: |
          PRE-DEPLOYMENT CHECKLIST:
          {% for item in checklist %}
          [ ] {{ item }}
          {% endfor %}
    
    - name: Require manual approval
      pause:
        prompt: |
          Complete all checklist items, then press ENTER to continue
          or Ctrl+C to abort deployment
```

## During Deployment Monitoring

```yaml
---
- name: Deploy with monitoring
  hosts: webservers
  serial: 1
  
  tasks:
    - name: Deployment metrics
      debug:
        msg: |
          Deploying to: {{ inventory_hostname }}
          Time: {{ ansible_date_time.iso8601 }}
          Progress: {{ ansible_loop.index }}/{{ ansible_loop.length }}
      loop: "{{ groups['webservers'] }}"
      loop_control:
        extended: yes
    
    - name: Monitor during deployment
      block:
        - name: Deployment task
          shell: /opt/deploy.sh
        
        - name: Monitor metrics
          shell: |
            curl http://prometheus:9090/api/v1/query?query=up{job="myapp"}
          register: metrics
        
        - name: Alert if issues detected
          mail:
            subject: "Deployment issue detected"
            body: "{{ metrics.stdout }}"
          when: "'0' in metrics.stdout"
      
      rescue:
        - name: Rollback on failure
          shell: /opt/rollback.sh
```

## Post-Deployment Validation

```yaml
---
- name: Post-deployment validation
  hosts: localhost
  gather_facts: no
  
  tasks:
    - name: Health checks
      uri:
        url: "http://{{ item }}:8080/health"
        status_code: 200
      loop: "{{ groups['webservers'] }}"
      retries: 5
      delay: 10
    
    - name: Smoke tests
      shell: /opt/smoke-tests.sh
      register: smoke_test_result
    
    - name: Verify success
      assert:
        that:
          - "'PASSED' in smoke_test_result.stdout"
        fail_msg: "Smoke tests failed!"
    
    - name: Database consistency check
      shell: /opt/db-check.sh
    
    - name: Performance baseline
      shell: |
        ab -n 1000 -c 10 http://{{ groups['webservers'][0] }}/
    
    - name: Notify success
      mail:
        subject: "Deployment successful"
        body: |
          Deployment completed successfully!
          All health checks passed.
          All smoke tests passed.
          Database consistency verified.
```

---

# SECTION 31: ADVANCED DEBUGGING TECHNIQUES

## Debugging Variables

```yaml
- name: Debug variables
  debug:
    var: my_variable
    # Shows: my_variable: [value]

- name: Debug with message
  debug:
    msg: "Variable value: {{ my_variable }}"

- name: Debug entire hostvars
  debug:
    var: hostvars[inventory_hostname]
  # Shows ALL variables for current host

- name: Debug specific var with verbosity
  debug:
    msg: "Debug info: {{ my_var }}"
    verbosity: 2
  # Only shows with: ansible-playbook -vv
```

## Debugging Task Execution

```yaml
- name: Task with debug output
  block:
    - name: Before task
      debug:
        msg: "About to run: {{ ansible_task_name }}"
    
    - name: The actual task
      shell: some_command
      register: result
    
    - name: After task
      debug:
        msg: |
          Task completed
          Return code: {{ result.rc }}
          Stdout: {{ result.stdout }}
          Stderr: {{ result.stderr }}
```

## Strategic Debugging Points

```yaml
---
- name: Deploy with debug checkpoints
  hosts: servers
  
  tasks:
    # CHECKPOINT 1: Before phase
    - name: CHECKPOINT 1 - Pre-deployment
      debug:
        msg: "Starting deployment to {{ inventory_hostname }}"
    
    # Phase 1 tasks
    - name: Phase 1 task 1
      shell: /opt/task1.sh
    
    # CHECKPOINT 2: After phase 1
    - name: CHECKPOINT 2 - Phase 1 complete
      debug:
        msg: |
          Phase 1 complete on {{ inventory_hostname }}
          Check system status before continuing
      when: enable_checkpoints | default(false) | bool
      pause:
        prompt: "Review above, then press ENTER to continue"
    
    # Phase 2 tasks
    - name: Phase 2 task 1
      shell: /opt/task2.sh
    
    # CHECKPOINT 3: Before cutover
    - name: CHECKPOINT 3 - Ready for cutover
      debug:
        msg: |
          System ready for cutover on {{ inventory_hostname }}
          All pre-checks complete
      when: enable_checkpoints | default(false) | bool
      pause:
        prompt: "Ready? Press ENTER to proceed with cutover"
    
    # Cutover
    - name: Cutover
      shell: /opt/cutover.sh
    
    # CHECKPOINT 4: Final validation
    - name: CHECKPOINT 4 - Deployment complete
      debug:
        msg: "Deployment complete on {{ inventory_hostname }}"
```

## Using Ansible Debugger

```bash
# Run with debugger enabled
$ ansible-playbook deploy.yml --strategy=debug

# In debugger, you can:
# - Print variables: p var_name
# - List tasks: list
# - Set variables: set_fact var_name=value
# - Continue: c
# - Quit: q
```

---

# SECTION 32: SCALING TO ENTERPRISE LEVEL

## Enterprise Architecture

```yaml
---
- name: Enterprise deployment
  hosts: all
  gather_facts: yes
  
  vars:
    # Multi-region setup
    regions:
      - region: us-east-1
        env: production
        servers: 50
      - region: eu-west-1
        env: production
        servers: 30
      - region: ap-southeast-1
        env: production
        servers: 20
    
    # High availability
    ha_enabled: true
    load_balancer: internal-lb.company.com
    
    # Logging centralization
    logging_server: logstash.company.com
    
    # Monitoring
    monitoring_server: prometheus.company.com
  
  pre_tasks:
    # Enterprise-grade pre-checks
    - name: Verify SSL certificates
      openssl_certificate_info:
        path: /etc/ssl/certs/mycert.pem
      register: cert_info
    
    - name: Check certificate validity
      assert:
        that:
          - cert_info.not_after | to_datetime > ansible_date_time.iso8601 | to_datetime
        fail_msg: "SSL certificate expired!"
    
    - name: Enterprise logging
      syslog:
        msg: "Ansible: Starting deployment on {{ inventory_hostname }}"
        facility: local0
        priority: info
  
  tasks:
    - name: Deploy with enterprise controls
      block:
        # Deployment logic
        - debug: msg="Enterprise deployment"
      
      rescue:
        - name: Enterprise failure logging
          syslog:
            msg: "Ansible: Deployment FAILED on {{ inventory_hostname }}"
            facility: local0
            priority: error
```

## Compliance and Audit

```yaml
---
- name: Compliance checks
  hosts: all
  gather_facts: yes
  
  tasks:
    - name: CIS Benchmark checks
      block:
        # Check password policies
        - name: Verify password policy
          shell: grep "minlen" /etc/security/pwquality.conf
          register: password_policy
        
        - name: Check SELinux
          gelinux: policy=targeted state=enforcing
        
        - name: Verify sudo logging
          lineinfile:
            path: /etc/sudoers
            regexp: 'Defaults.*logfile'
            line: 'Defaults logfile="/var/log/sudo.log"'
        
        - name: Audit logging
          shell: |
            auditctl -a always,exit -F path=/etc/passwd -F perm=wa -k passwd_changes
    
    - name: Generate compliance report
      template:
        src: compliance_report.j2
        dest: /var/log/compliance/{{ inventory_hostname }}_{{ ansible_date_time.date }}.html
      vars:
        checks_passed: 45
        checks_failed: 2
        compliance_percentage: 95.7
```

---

# SECTION 33: INTERVIEW QUESTIONS AND ANSWERS

## Beginner Level

**Q1: What is Ansible and why would you use it?**
A: Ansible is an agentless IT automation tool. You'd use it because:
- Simple (YAML, no coding knowledge needed)
- Agentless (uses SSH, no installation)
- Idempotent (safe to run repeatedly)
- Idempotent (safe to run repeatedly)
- Perfect for configuration management, deployment, and orchestration

**Q2: Explain the difference between a playbook and a role.**
A: 
- Playbook: A file that contains tasks, plays, and roles. It's executed directly.
- Role: A directory structure with organized tasks, handlers, templates, etc. Reusable across projects.

**Q3: What is an inventory in Ansible?**
A: An inventory is a file/source that defines which servers Ansible manages. It can be:
- Static (manually written INI/YAML files)
- Dynamic (queried from cloud APIs like AWS)

## Intermediate Level

**Q4: Explain variable precedence in Ansible.**
A: Variables override each other in this order (low to high priority):
1. Role defaults
2. Inventory variables
3. Group vars
4. Host vars
5. Role vars
6. Block vars
7. Task vars
8. Extra vars (-e) - HIGHEST

**Q5: What's the difference between handlers and tasks?**
A: 
- Tasks: Run every time (unless skipped)
- Handlers: Run only when notified by a task AND that task changed something

**Q6: How would you deploy an application with zero downtime?**
A: Use blue-green or canary deployment:
- Blue-Green: Run two environments, switch load balancer between them
- Canary: Deploy to 10% of servers first, then full deployment

## Advanced Level

**Q7: Design a production deployment pipeline using GitLab CI/CD and Ansible.**
A: 
```
1. Lint stage: ansible-lint, yamllint
2. Test stage: molecule test
3. Deploy staging: ansible-playbook (check mode first)
4. Manual approval
5. Deploy production: rolling update with health checks
6. Rollback capability: automated rollback on failure
```

**Q8: How would you manage secrets securely in production?**
A:
- Use Ansible Vault for encryption at rest
- Store vault password in CI/CD secrets, not in Git
- Rotate secrets regularly
- Use role-based access control (RBAC)
- Log access to secrets

**Q9: Describe how you'd scale Ansible to manage 10,000 servers.**
A:
- Use dynamic inventory (auto-discovery)
- Use Ansible Tower/AWX for centralized control
- Implement fact caching
- Increase forks for parallelization
- Use async for long-running tasks
- Organize code with collections and roles
- Implement monitoring and logging
- Use multi-region/multi-cloud approach

**Q10: What's your approach to testing Ansible playbooks?**
A:
- Unit testing: Molecule tests for roles
- Integration testing: Test actual deployments
- Smoke testing: Quick validation post-deployment
- Idempotence testing: Run twice, verify identical results
- CI/CD integration: Automated testing before production

---

# COMPLETE FINAL SUMMARY

**Total Content: 4,916+ lines**

## What You Have Learned

### Core Concepts (Sections 1-12)
✅ Ansible fundamentals
✅ Inventory management (static & dynamic)
✅ Playbooks & roles
✅ Variables & filters
✅ Conditionals & loops
✅ Handlers & templates
✅ Modules & vault

### Practical Implementation (Sections 13-19)
✅ Error handling & rollback
✅ Tags & selective execution
✅ Multiple server management
✅ Real-world scenarios
✅ Troubleshooting (30+ solutions)
✅ Best practices
✅ Quick reference

### Enterprise Features (Sections 20-33)
✅ GitLab CI/CD integration
✅ Ansible Tower/AWX
✅ Advanced Jinja2 filters
✅ Advanced playbook patterns
✅ Performance optimization
✅ Security best practices
✅ Molecule testing
✅ Multi-cloud deployment
✅ Production checklist
✅ Advanced debugging
✅ Enterprise scaling
✅ Compliance & audit
✅ Interview prep

### Complete Coverage
✅ 33 comprehensive sections
✅ 150+ code examples
✅ 50+ real-world scenarios
✅ 30+ troubleshooting solutions
✅ 10+ interview questions with detailed answers
✅ Production-ready patterns
✅ Enterprise-grade practices

---

## You Are Now Ready For:

✅ **Job Interviews** - Deep knowledge across all topics
✅ **Certifications** - CKA, ACP, RHCE level understanding
✅ **Production Deployment** - Enterprise-grade deployments
✅ **Complex Automation** - Multi-cloud, multi-region scenarios
✅ **Team Leadership** - Can guide others and set best practices
✅ **Large Scale** - Scaling to 1000s of servers

---

## Next Learning Path

After mastering this guide:
1. **Practice** - Deploy real applications with Ansible
2. **Experiment** - Try different scenarios and patterns
3. **Contribute** - Contribute to Ansible project
4. **Specialize** - Focus on specific areas (cloud, containers, etc.)
5. **Certify** - Get official Ansible certification

---

**🎓 CONGRATULATIONS! YOU ARE NOW AN ANSIBLE EXPERT!**

**Your comprehensive guide has 4,916+ lines of detailed explanations covering everything from beginner fundamentals to expert-level enterprise deployment!**

