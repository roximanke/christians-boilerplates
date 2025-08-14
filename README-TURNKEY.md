# 🚀 Turnkey Deployment Solution

This repository has been enhanced with a comprehensive turnkey deployment solution that transforms all the infrastructure configurations into easily deployable, standalone applications.

## 📋 Overview

The turnkey solution provides:
- **Unified CLI Tool** - Single command interface for all deployments
- **Modern Web Dashboard** - Beautiful UI for managing deployments
- **Automated Environment Setup** - Template generation for configuration
- **Comprehensive Logging** - Full audit trail of all operations
- **Multi-Platform Support** - Docker, Kubernetes, Ansible, Terraform, and Vagrant

## 🎯 Quick Start

### 1. Check Dependencies
```bash
./check-dependencies.sh
```

### 2. Setup Environment Templates
```bash
./scripts/setup-env-templates.sh
```

### 3. Launch CLI Interface
```bash
./run.sh
```

### 4. Launch Web Dashboard
```bash
cd dashboard
python3 server.py
```
Then open http://localhost:8000 in your browser.

## 🛠️ Components

### Core Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `check-dependencies.sh` | Verify system requirements | `./check-dependencies.sh` |
| `run.sh` | Main CLI interface | `./run.sh` |
| `scripts/run-docker.sh` | Deploy Docker Compose apps | `./scripts/run-docker.sh grafana` |
| `scripts/run-ansible.sh` | Run Ansible playbooks | `./scripts/run-ansible.sh ansible/docker/inst-docker-ubuntu.yaml` |
| `scripts/run-k8s.sh` | Deploy Kubernetes apps | `./scripts/run-k8s.sh portainer` |
| `scripts/run-terraform.sh` | Apply Terraform configs | `./scripts/run-terraform.sh proxmox` |
| `scripts/setup-env-templates.sh` | Create environment templates | `./scripts/setup-env-templates.sh` |

### Web Dashboard

The modern web dashboard provides:
- **Application Management** - Deploy, stop, and monitor applications
- **Real-time Logs** - View deployment logs and system output
- **Status Monitoring** - Track running services and system health
- **System Management** - Check dependencies and manage configurations

**Features:**
- Clean, modern UI with responsive design
- No external dependencies (self-contained)
- Real-time status updates
- Comprehensive logging interface
- Mobile-friendly responsive layout

## 📦 Supported Applications

### Docker Compose Applications (30+ apps)
- **Monitoring**: Grafana, Prometheus, Loki, Alloy
- **Development**: GitLab, Gitea, Portainer, Dockge
- **Productivity**: Nextcloud, Heimdall, Homepage, Homer
- **Security**: Authentik, Passbolt, Wazuh
- **Infrastructure**: Traefik, Nginx, MariaDB, PostgreSQL
- **And many more...**

### Kubernetes Applications
- **Container Management**: Portainer
- **Identity & Access**: Authentik
- **Ingress**: Traefik
- **Certificate Management**: cert-manager
- **Storage**: Longhorn

### Ansible Playbooks
- **System Setup**: Docker installation, Kubernetes setup
- **Maintenance**: APT updates, disk cleanup, reboots
- **Services**: Portainer deployment, Traefik setup
- **Security**: SSH key management, WireGuard VPN
- **Monitoring**: CheckMK integration

### Terraform Configurations
- **Virtualization**: Proxmox VM provisioning
- **Cloud**: Multi-cloud infrastructure
- **DNS**: Cloudflare management
- **Networking**: Network infrastructure

## 🔧 Configuration

### Environment Variables

Each Docker Compose application automatically gets a `.env` template file with secure defaults:

```bash
# Example: docker-compose/nextcloud/.env
MYSQL_PASSWORD=changeme_secure_password_a1b2c3d4
MYSQL_DATABASE=nextcloud_database
MYSQL_USER=nextcloud_user
MYSQL_HOST=localhost
```

### Ansible Inventory

Default inventory file is created at `ansible/inventory`:

```ini
[local]
localhost ansible_connection=local

[servers]
# Add your servers here
# server1 ansible_host=192.168.1.100 ansible_user=ubuntu

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

### Terraform Variables

Template `terraform.tfvars` files are automatically generated:

```hcl
# Example: terraform/proxmox/terraform.tfvars
target_node = "your-proxmox-node"
vm_name = "your-vm-name"
ssh_key = "your-ssh-public-key"
```

## 🚀 Usage Examples

### Deploy Docker Application
```bash
# Using CLI
./run.sh
# Select: 1) Docker Compose Application
# Choose: grafana

# Using script directly
./scripts/run-docker.sh grafana
```

### Run Ansible Playbook
```bash
# Using CLI
./run.sh
# Select: 2) Ansible Playbook
# Choose: inst-docker-ubuntu

# Using script directly
./scripts/run-ansible.sh ansible/docker/inst-docker-ubuntu.yaml
```

### Deploy Kubernetes Application
```bash
# Using CLI
./run.sh
# Select: 3) Kubernetes Application
# Choose: portainer

# Using script directly
./scripts/run-k8s.sh portainer
```

### Apply Terraform Configuration
```bash
# Using CLI
./run.sh
# Select: 4) Terraform Configuration
# Choose: proxmox

# Using script directly
./scripts/run-terraform.sh proxmox
```

## 📊 Web Dashboard Usage

1. **Start the Dashboard Server**:
   ```bash
   cd dashboard
   python3 server.py
   ```

2. **Access the Dashboard**:
   Open http://localhost:8000 in your browser

3. **Navigate Applications**:
   - **Docker Compose**: Deploy containerized applications
   - **Kubernetes**: Manage K8s deployments
   - **Ansible**: Run automation playbooks
   - **Terraform**: Provision infrastructure

4. **Monitor Operations**:
   - View real-time logs
   - Check system status
   - Monitor running services

## 🔒 Security Best Practices

### Environment Files
- All `.env` files are automatically generated with secure random passwords
- Add `*.env` to `.gitignore` to prevent committing secrets
- Review and update all template values before deployment

### SSH Keys
- Use SSH key authentication for remote deployments
- Store private keys securely and never commit them
- Use different keys for different environments

### Secrets Management
- Ansible secrets are stored in `secrets.yaml` files
- Use Ansible Vault for production secrets
- Terraform sensitive variables should use `.tfvars` files

## 📝 Logging

All operations are logged to `logs/deployment.log` with timestamps:

```
[2024-01-15 10:30:15] [DOCKER] Starting deployment of grafana
[2024-01-15 10:30:16] [DOCKER] Pulling latest images for grafana
[2024-01-15 10:30:20] [DOCKER] Starting grafana containers
[2024-01-15 10:30:25] [DOCKER] Successfully deployed grafana
```

## 🛠️ Troubleshooting

### Common Issues

**Docker daemon not running**:
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

**Permission denied on scripts**:
```bash
chmod +x *.sh scripts/*.sh
```

**Missing dependencies**:
```bash
./check-dependencies.sh
# Follow the installation hints provided
```

**Environment variables not set**:
```bash
./scripts/setup-env-templates.sh
# Edit the generated .env files
```

### Getting Help

1. **Check Logs**: `tail -f logs/deployment.log`
2. **Verify Dependencies**: `./check-dependencies.sh`
3. **Test Individual Components**: Use the specific run scripts
4. **Check Service Status**: Use the web dashboard or CLI status option

## 🔄 Updates and Maintenance

### Updating Applications
```bash
# Pull latest images
./scripts/run-docker.sh <app-name>

# Update Helm charts
./scripts/run-k8s.sh <app-name>
```

### System Maintenance
```bash
# Check system health
./run.sh
# Select: 8) Show Status

# Stop all services
./run.sh
# Select: 9) Stop All Services
```

### Backup Configurations
```bash
# Backup environment files
tar -czf env-backup-$(date +%Y%m%d).tar.gz docker-compose/*/.env

# Backup Terraform state
tar -czf terraform-backup-$(date +%Y%m%d).tar.gz terraform/*/terraform.tfstate*
```

## 🎨 Customization

### Adding New Applications

1. **Docker Compose**: Add new directory under `docker-compose/`
2. **Kubernetes**: Add manifests under `kubernetes/`
3. **Ansible**: Add playbooks under `ansible/`
4. **Terraform**: Add configurations under `terraform/`

The turnkey system will automatically detect and include new applications.

### Modifying the Dashboard

- **Styling**: Edit `dashboard/index.html` CSS variables
- **Functionality**: Modify `dashboard/app.js`
- **Backend**: Update `dashboard/server.py`

## 📈 Monitoring and Observability

The solution includes built-in monitoring through:
- **Grafana**: Metrics visualization
- **Prometheus**: Metrics collection
- **Loki**: Log aggregation
- **Alloy**: Telemetry collection

Deploy the monitoring stack:
```bash
./scripts/run-docker.sh grafana
./scripts/run-docker.sh prometheus
./scripts/run-docker.sh loki
```

## 🤝 Contributing

To contribute to the turnkey solution:

1. Test your changes with `./check-dependencies.sh`
2. Ensure all scripts are executable
3. Update documentation as needed
4. Test both CLI and web interfaces

## 📄 License

This turnkey solution maintains the same license as the original repository.

---

**🎉 Congratulations!** You now have a complete turnkey deployment solution that transforms complex infrastructure configurations into simple, one-click deployments. Whether you prefer the command line or a modern web interface, you can deploy and manage your entire infrastructure with ease.
