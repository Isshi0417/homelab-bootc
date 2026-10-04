# Declarativev Immutable Homelab & GitOps Platform (v2)

![OS](https://img.shields.io/badge/OS-CentOS%20Stream%209%20Bootc-EE0000?logo=redhat)

![Automation](https://img.shields.io/badge/Ansible-Navigator%20%26%20AAP-%20%20%20red?logo=ansible)

![Containers](https://img.shields.io/badge/Containers-Podman%20Quadlets-%20%20%20892CA0?logo=podman)

![Security](https://img.shields.io/badge/SELinux-Enforcing-%20%20%20success)

![Zero-Trust](https://img.shields.io/badge/Ingress-Cloudflare%20Zero--%20%20%20Trust-F38020?logo=cloudflare)

![Storage](https://img.shields.io/badge/Cloud%20Storage-%20%20%20Google%20Drive%20FUSE-4285F4?logo=google)

![DevEx](https://img.shields.io/badge/DevEx-DevContainer%20%2B%20Nushell-%20%20%204E9A06)



A declarative, production-grade private cloud platform engineered on bare-metal immutable **CentOS Stream 9 Bootc**. Built under the **KISS (Keep It Simple, Stupid)** philosophy, eliminating nested hypervisor overhead by running workloads as native, rootless **Podman Quadlets** under strict **SELinux Enforcing** mode. Orchestrated entirely via **Ansible Navigator** following Red Hat Enterprise (RHCSA / RHCE) standards.



---



## System Architecture

```mermaid
flowchart TB
    subgraph External["External Cloud & Edge Services"]
        Edge["Cloudflare Edge (WAF, SSL, DDos Protection)"]
        GDrive["Google Drive API (Music Library & Remote Backups)"]
        User["Public Users / Recruiters"]
    end

    subgraph BareMetal["Bare-Metal Host: CentOS Stream 9 Bootc"]
        direction TB

        subgraph CoreOS["Immutable OS Core (bootc)"]
            Kernel["Linux Kernel (crashkernel=no, tuned: throughput-performance"]
            Watchdog["Systemd Hardware Watchdog & Journald Caps"]
            Linger["Systemd User Lingering (homelab:1001)"]
            BackupTimer["Systemd Timer: homelab-backup.timer (03:00 Daily)"]
        end

        subgraph StorageLayer["FUSE & Watchdog & Journald Caps"]
            RcloneMount["rclone-gdrive.service (FUSE :ro Mount)"]
            BackupScript["homelab-backup.service (tar + rclone copy + prune)"]
        end

        subgraph UserSpace["Unprivileged Service Context: homelab (UID 1001)"]
            direction TB
            Net["Podman Bridge Network: homelab-net (10.89.0.0/24)"]

            subgraph Ingress["Edge Gateway (Zero Exposed Host Ports)"]
                CFTunnel["cloudflared Quadlet (Zero-Trust Connector)"]
            end

            subgraph Workloads["Application Quadlets (:Z SELinux Isolated)"]
                Portfolio["Personal Portfolio Quadlet (:8080)<br/>ReadOnly Root | Drop Capabilities"]
                Navidrome["Navidrome Music Quadlet (:4533)<br/>Dual Volume Mounts (:ro,Z / :rw,Z)"]
                Gitea["Gitea git Server Quadlet (:3000)<br/>Embedded High-Performance SQLite"]
                Uptime["Uptime Kuma Health Quadlet (:3001)<br/>Internal Metric & Probe Polling"]
            end
        end

        subgraph Storage["Persistent Host Storage (/var/homelab)"]
            DataPort["/var/homelab/portfolio/html"]
            DataNavMusic["/var/homelab/navidrome/music (FUSE Stream)"]
            DataNavDB["/var/homelab/navidrome/data (:rw)"]
            DataGit["/var/homelab/gitea/data (:rw)"]
            DataKuma["/var/homelab/uptime-kuma/data (:rw)"]
            LocalBackup["/var/homelab/backups (7-day local cache)"]
        end
    end

    %% Edge Ingress Flows
    User -->|HTTPS| Edge
    Edge -->|Zero-Trust Tunnel| CFTunnel
    CFTunnel -->|http://portfolio:88080| Portfolio
    CFTunnel -->|http://navidrome:4533| Navidrome
    CFTunnel -->|http://gitea:3000| Gitea
    CFTunnel -->|http://uptime-kuma:3001| Uptime

    %% Storage & Cloud Sync Flows
    GDrive <-->|VFS Full Cache| RcloneMount
    RcloneMount -->|Mount :ro| DataNavMusic
    Navidrome -.->|Mount :ro,Z| DataNavMusic
    Navidrome -.->|Mount :rw,Z| DataNavDB
    Portfolio -.->|Mount :ro,Z| DataPort
    Gitea -.->|Mount :rw,Z| DataGit
    Uptime -.->|Mount :rw,Z| DataKuma

    %% Backup Automation Flows
    BackupTimer -->|Trigger 03:00| BackupScript
    BackupScript -->|Archive & Compress| LocalBackup
    BackupScript -->|rclone copy & 30d prune| GDrive
```



---



## Core Engineering Competencies Demonstrated

### Enterprise Linux & RHCSA Competencies

* Immutable Operating System (`bootc`): Bootable OCi container image (`quay.io/centos-booc/centos-bootc:stream9`) managing OS deployment, rollback, and automated transactional upgrades via `bootc-fetch-apply-updates.timer`.

* Strict SELinux Enforcement: System runs in enforcing mode. All persistent directories and bind mounts strictly apply `container_file_t` contexts with `:Z` private volume relabeling.

* Systemd User Lingering: Configures rootless systemd execution via `loginctl enable-linger homelab`. Workloads launch as systemd services at boot without active user logins.

* Automated Maintenance Timers: Configures native systemd calendar timers (`homelab-backup.timer`) executing daily backups at 03:00 with auto-pruning.

* FUSE3 Integration: Enables `user_allow_other` in `/etc/fuse.conf` and mounts cloud file systems with VFS caching.



### Modern Configuration Management & RHCE Standards

* Principle of Least Privilege: Global `become = False` in `ansible.cfg`. Privilege escalation (`sudo`) is scoped strictly to tasks requiring administrative privileges.

* Red Hat Ansible Navigator: Fully configured for containerized execution environments (AAP 2.x Standard) using `ansible-navigator.yml`, with log output isolated to /tmp to maintain a clean git workspace.

* Native AES-256 Ansible Vault: Secrets (Cloudflare tokens, Google Drive OAuth tokens, passwords) are encrypted natively via Ansible Vault (`--vault-id`), accompanied by a sanitized `vault.example.yml` schema template.

* SSH Optimization: Pipelining and `ControlMaster` socket multiplexing enabled for ultra-fast task execution.



### Daemonless Containerization (Podman Quadlet)

* Native Systemd Integration: Eliminates Docker Compose in favor of native systemd Quadlet generators (`.container`, `.network`) in `~homelab/config/containers/systemd/`.

* Security Sandboxing: Workload containers drop Linux capabilities (`DropCapability=ALL`) and enforce immutable root filesystems (`ReadOnly=true`).

* Automated Registry Updates: Quadlets specificy `AutoUpdate=registry` for automated container image patching via `podman-auto-update.timer`.



### Zero-Trust Ingress & Git Hygiene

* Zero Exposed Inbound Ports: Public traffic reaches workloads exclusively through encrypted Cloudflare Zero-Trust Tunnels, bypassing CGNAT and eliminating firewall attack surfaces.

* Pre-Commit Filter Pipeline: Enforces trailing-whitespace stripping, POSIX EOF normalization, YAML validation, Gitleaks secret leak detection, and native `ansible-lint` compliance before any commit is accepted.



---



## Operational Runbook

### Environment Initialization

Launch the included DevContainer in VS Code (powered by Fedora 41 and Nushell), or initialize your local environment:

```bash
# Verify available commands
just --list

# Install git pre-commit hooks
just init
```



### Secret Configuration (Ansible Vault)

Create your local vault password file and configure platform secrets:

```bash
# Set your locla vault decryption password (ignored by git)
echo "your-strong-vault-password" > .vault_pass

# Copy the secrets template
cp ansible/inventory/group_vars/all/vault.example.yml \
    ansible/inventory/group_vars/all/vault.yml

# Fill in your real Cloudflare token, Google Drivev OAuth tokens, and passwords

# Encrypt your secrets using AES-256
just vault-encrypt ansible/inventory/group_vars/all/vault.yml
```



### Syntax Verification & Quality Check

Run the automated test suite:

```bash
# Verify playbook syntax
just ansible-check

# Run full pre-commit security and linting suite
just lint
```





### Platform Convergence (Ansible Navigator)

```bash
# Converge platform via standard stdout
just ansible-apply

# Or launch the interactive Red Hat Navigator TUI
just ansible-tui
```



---



## Service Endpoints

| Service            | Endpoint                  | Technology                   | Storage & Security Profile                            |
| ------------------ | ------------------------- | ---------------------------- | ----------------------------------------------------- |
| Personal Portfolio | https://shooey.xyz        | Nginx Alpine Quadlet         | Read-Only Root, Drop ALL Capabilities                 |
| Navidrome Music    | https://music.shooey.xyz  | Navidrome Quadlet            | Google Drive FUSE Mount (`:ro,Z`), Dual Volume Mounts |
| Gitea Git Server   | https://git.shooey.xyz    | Gitea Rootless Quadlet       | High-Performance SQLite, Non-Root UID                 |
| Uptime Dashboard   | https://status.shooey.xyz | Uptime Kuma Quadlet          | Inernal Health Check Polling                          |
| Server Backup      | gdrive:homelab-backups    | Systemd Timer + Rclone       | 03:00 Daily Schedule, 30-Day Retention Pruning        |
| Edge Gateway       | Zero open host ports      | Cloudflare Zero-Trust Tunnel | End-to-End Encrypted Tunnel                           |
