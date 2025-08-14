// Turnkey Deployment Dashboard - JavaScript Application
// Handles UI interactions and API calls for deployment management

class DeploymentDashboard {
    constructor() {
        this.currentSection = 'docker';
        this.apps = {
            docker: [],
            kubernetes: [],
            ansible: [],
            terraform: []
        };
        this.init();
    }

    async init() {
        await this.loadApplications();
        this.updateStats();
        this.startPolling();
    }

    // Load applications from the file system structure
    async loadApplications() {
        try {
            // Simulate loading Docker Compose apps
            this.apps.docker = [
                { name: 'grafana', status: 'stopped', description: 'Monitoring and observability platform', ports: ['3000:3000'] },
                { name: 'nextcloud', status: 'unknown', description: 'Self-hosted cloud storage and collaboration', ports: ['80:80'] },
                { name: 'portainer', status: 'unknown', description: 'Docker container management UI', ports: ['9000:9000', '9443:9443'] },
                { name: 'prometheus', status: 'unknown', description: 'Monitoring system and time series database', ports: ['9090:9090'] },
                { name: 'traefik', status: 'unknown', description: 'Modern reverse proxy and load balancer', ports: ['80:80', '443:443'] },
                { name: 'gitlab', status: 'unknown', description: 'DevOps platform with Git repository management', ports: ['80:80', '443:443', '22:22'] },
                { name: 'postgres', status: 'unknown', description: 'PostgreSQL database server', ports: ['5432:5432'] },
                { name: 'mariadb', status: 'unknown', description: 'MariaDB database server', ports: ['3306:3306'] },
                { name: 'nginx', status: 'unknown', description: 'High-performance web server and reverse proxy', ports: ['80:80', '443:443'] },
                { name: 'pihole', status: 'unknown', description: 'Network-wide ad blocker and DNS server', ports: ['53:53', '80:80'] }
            ];

            // Simulate loading Kubernetes apps
            this.apps.kubernetes = [
                { name: 'portainer', status: 'unknown', description: 'Container management for Kubernetes', type: 'helm' },
                { name: 'authentik', status: 'unknown', description: 'Identity provider and SSO solution', type: 'helm' },
                { name: 'traefik', status: 'unknown', description: 'Kubernetes ingress controller', type: 'manifest' },
                { name: 'cert-manager', status: 'unknown', description: 'Automatic TLS certificate management', type: 'helm' }
            ];

            // Simulate loading Ansible playbooks
            this.apps.ansible = [
                { name: 'inst-docker-ubuntu', status: 'unknown', description: 'Install Docker on Ubuntu systems', path: 'ansible/docker/inst-docker-ubuntu.yaml' },
                { name: 'inst-k8s', status: 'unknown', description: 'Install Kubernetes cluster', path: 'ansible/kubernetes/inst-k8s.yaml' },
                { name: 'deploy-portainer', status: 'unknown', description: 'Deploy Portainer using Ansible', path: 'ansible/portainer/deploy-portainer.yaml' },
                { name: 'inst-wireguard', status: 'unknown', description: 'Install and configure WireGuard VPN', path: 'ansible/wireguard/inst-wireguard.yaml' },
                { name: 'upd-apt', status: 'unknown', description: 'Update APT packages on Ubuntu', path: 'ansible/ubuntu/upd-apt.yaml' }
            ];

            // Simulate loading Terraform configurations
            this.apps.terraform = [
                { name: 'proxmox', status: 'unknown', description: 'Deploy VMs on Proxmox infrastructure', resources: ['VM', 'Network'] },
                { name: 'cloudflare', status: 'unknown', description: 'Manage Cloudflare DNS and security', resources: ['DNS', 'Firewall'] },
                { name: 'kubernetes', status: 'unknown', description: 'Provision Kubernetes cluster infrastructure', resources: ['Cluster', 'Nodes'] }
            ];

            this.renderApplications();
        } catch (error) {
            this.showNotification('Failed to load applications', 'error');
            console.error('Error loading applications:', error);
        }
    }

    // Render applications for the current section
    renderApplications() {
        const section = document.getElementById(`${this.currentSection}-section`);
        if (!section) return;

        const apps = this.apps[this.currentSection];
        
        section.innerHTML = apps.map(app => {
            switch (this.currentSection) {
                case 'docker':
                    return this.renderDockerApp(app);
                case 'kubernetes':
                    return this.renderKubernetesApp(app);
                case 'ansible':
                    return this.renderAnsibleApp(app);
                case 'terraform':
                    return this.renderTerraformApp(app);
                default:
                    return '';
            }
        }).join('');
    }

    renderDockerApp(app) {
        const statusClass = app.status === 'running' ? 'status-running' : 
                           app.status === 'stopped' ? 'status-stopped' : 'status-unknown';
        
        return `
            <div class="app-card">
                <div class="app-header">
                    <div class="app-title">${app.name}</div>
                    <div class="app-description">${app.description}</div>
                    <div class="app-status ${statusClass}">${app.status}</div>
                    ${app.ports ? `<div style="margin-top: 0.5rem; font-size: 0.75rem; color: var(--text-secondary);">Ports: ${app.ports.join(', ')}</div>` : ''}
                </div>
                <div class="app-actions">
                    <button class="btn btn-primary" onclick="dashboard.deployApp('docker', '${app.name}')">
                        Deploy
                    </button>
                    <button class="btn btn-secondary" onclick="dashboard.showLogs('docker', '${app.name}')">
                        Logs
                    </button>
                    <button class="btn btn-danger" onclick="dashboard.stopApp('docker', '${app.name}')">
                        Stop
                    </button>
                </div>
            </div>
        `;
    }

    renderKubernetesApp(app) {
        const statusClass = app.status === 'running' ? 'status-running' : 
                           app.status === 'stopped' ? 'status-stopped' : 'status-unknown';
        
        return `
            <div class="app-card">
                <div class="app-header">
                    <div class="app-title">${app.name}</div>
                    <div class="app-description">${app.description}</div>
                    <div class="app-status ${statusClass}">${app.status}</div>
                    <div style="margin-top: 0.5rem; font-size: 0.75rem; color: var(--text-secondary);">Type: ${app.type}</div>
                </div>
                <div class="app-actions">
                    <button class="btn btn-primary" onclick="dashboard.deployApp('kubernetes', '${app.name}')">
                        Deploy
                    </button>
                    <button class="btn btn-secondary" onclick="dashboard.showLogs('kubernetes', '${app.name}')">
                        Logs
                    </button>
                    <button class="btn btn-danger" onclick="dashboard.stopApp('kubernetes', '${app.name}')">
                        Remove
                    </button>
                </div>
            </div>
        `;
    }

    renderAnsibleApp(app) {
        return `
            <div class="app-card">
                <div class="app-header">
                    <div class="app-title">${app.name}</div>
                    <div class="app-description">${app.description}</div>
                    <div style="margin-top: 0.5rem; font-size: 0.75rem; color: var(--text-secondary);">Path: ${app.path}</div>
                </div>
                <div class="app-actions">
                    <button class="btn btn-primary" onclick="dashboard.deployApp('ansible', '${app.name}')">
                        Run Playbook
                    </button>
                    <button class="btn btn-secondary" onclick="dashboard.showLogs('ansible', '${app.name}')">
                        Logs
                    </button>
                </div>
            </div>
        `;
    }

    renderTerraformApp(app) {
        const statusClass = app.status === 'running' ? 'status-running' : 
                           app.status === 'stopped' ? 'status-stopped' : 'status-unknown';
        
        return `
            <div class="app-card">
                <div class="app-header">
                    <div class="app-title">${app.name}</div>
                    <div class="app-description">${app.description}</div>
                    <div class="app-status ${statusClass}">${app.status}</div>
                    ${app.resources ? `<div style="margin-top: 0.5rem; font-size: 0.75rem; color: var(--text-secondary);">Resources: ${app.resources.join(', ')}</div>` : ''}
                </div>
                <div class="app-actions">
                    <button class="btn btn-primary" onclick="dashboard.deployApp('terraform', '${app.name}')">
                        Apply
                    </button>
                    <button class="btn btn-secondary" onclick="dashboard.showLogs('terraform', '${app.name}')">
                        Logs
                    </button>
                    <button class="btn btn-danger" onclick="dashboard.stopApp('terraform', '${app.name}')">
                        Destroy
                    </button>
                </div>
            </div>
        `;
    }

    // Show specific section
    showSection(section) {
        // Update navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
        event.target.classList.add('active');

        // Hide all sections
        document.querySelectorAll('[id$="-section"]').forEach(section => {
            section.classList.add('hidden');
        });

        // Show selected section
        const targetSection = document.getElementById(`${section}-section`);
        if (targetSection) {
            targetSection.classList.remove('hidden');
        }

        // Update header
        const titles = {
            docker: 'Docker Compose Applications',
            kubernetes: 'Kubernetes Applications',
            ansible: 'Ansible Playbooks',
            terraform: 'Terraform Configurations',
            logs: 'Deployment Logs',
            settings: 'System Settings'
        };

        const descriptions = {
            docker: 'Deploy and manage containerized applications',
            kubernetes: 'Deploy applications to Kubernetes clusters',
            ansible: 'Run automation playbooks and configurations',
            terraform: 'Provision and manage infrastructure',
            logs: 'View deployment logs and system output',
            settings: 'System configuration and management'
        };

        document.getElementById('section-title').textContent = titles[section] || section;
        document.getElementById('section-description').textContent = descriptions[section] || '';

        this.currentSection = section;
        
        if (section === 'logs') {
            this.refreshLogs();
        }
    }

    // Deploy application
    async deployApp(type, name) {
        this.showNotification(`Deploying ${name}...`, 'success');
        
        try {
            // Simulate deployment API call
            console.log(`Deploying ${type} application: ${name}`);
            
            // In a real implementation, this would call the backend API
            // const response = await fetch(`/api/deploy/${type}/${name}`, { method: 'POST' });
            
            // Simulate deployment time
            await new Promise(resolve => setTimeout(resolve, 2000));
            
            // Update app status
            const app = this.apps[type].find(a => a.name === name);
            if (app) {
                app.status = 'running';
                this.renderApplications();
                this.updateStats();
            }
            
            this.showNotification(`${name} deployed successfully!`, 'success');
        } catch (error) {
            this.showNotification(`Failed to deploy ${name}`, 'error');
            console.error('Deployment error:', error);
        }
    }

    // Stop application
    async stopApp(type, name) {
        this.showNotification(`Stopping ${name}...`, 'success');
        
        try {
            console.log(`Stopping ${type} application: ${name}`);
            
            // Simulate stop time
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            // Update app status
            const app = this.apps[type].find(a => a.name === name);
            if (app) {
                app.status = 'stopped';
                this.renderApplications();
                this.updateStats();
            }
            
            this.showNotification(`${name} stopped successfully!`, 'success');
        } catch (error) {
            this.showNotification(`Failed to stop ${name}`, 'error');
            console.error('Stop error:', error);
        }
    }

    // Show logs for application
    showLogs(type, name) {
        this.showSection('logs');
        document.getElementById('logs-content').innerHTML = `
            <div style="color: #10b981;">[INFO] Showing logs for ${type}/${name}</div>
            <div style="color: #64748b;">[$(new Date().toISOString())] Starting deployment...</div>
            <div style="color: #64748b;">[$(new Date().toISOString())] Pulling images...</div>
            <div style="color: #10b981;">[$(new Date().toISOString())] Images pulled successfully</div>
            <div style="color: #64748b;">[$(new Date().toISOString())] Creating containers...</div>
            <div style="color: #10b981;">[$(new Date().toISOString())] Containers created</div>
            <div style="color: #64748b;">[$(new Date().toISOString())] Starting services...</div>
            <div style="color: #10b981;">[$(new Date().toISOString())] ${name} is now running</div>
            <div style="color: #f59e0b;">[$(new Date().toISOString())] Waiting for health checks...</div>
            <div style="color: #10b981;">[$(new Date().toISOString())] Health checks passed</div>
            <div style="color: #10b981;">[$(new Date().toISOString())] Deployment completed successfully</div>
        `;
    }

    // Refresh logs
    refreshLogs() {
        const logsContent = document.getElementById('logs-content');
        logsContent.innerHTML = 'Loading logs...';
        
        // Simulate loading logs
        setTimeout(() => {
            logsContent.innerHTML = `
                <div style="color: #10b981;">[INFO] System logs refreshed at ${new Date().toLocaleTimeString()}</div>
                <div style="color: #64748b;">[$(new Date().toISOString())] Dashboard initialized</div>
                <div style="color: #64748b;">[$(new Date().toISOString())] Loading applications...</div>
                <div style="color: #10b981;">[$(new Date().toISOString())] Found ${this.getTotalApps()} applications</div>
                <div style="color: #64748b;">[$(new Date().toISOString())] Checking service status...</div>
                <div style="color: #10b981;">[$(new Date().toISOString())] Status check completed</div>
                <div style="color: #f59e0b;">[$(new Date().toISOString())] Some services are not running</div>
                <div style="color: #64748b;">[$(new Date().toISOString())] Dashboard ready</div>
            `;
        }, 1000);
    }

    // Update statistics
    updateStats() {
        const runningCount = Object.values(this.apps).flat().filter(app => app.status === 'running').length;
        const totalApps = this.getTotalApps();
        
        document.getElementById('running-count').textContent = runningCount;
        document.getElementById('total-apps').textContent = totalApps;
        document.getElementById('last-deployment').textContent = new Date().toLocaleTimeString();
    }

    getTotalApps() {
        return Object.values(this.apps).flat().length;
    }

    // System management functions
    checkDependencies() {
        this.showNotification('Checking system dependencies...', 'success');
        console.log('Running dependency check...');
        // In real implementation, this would call the check-dependencies.sh script
    }

    setupEnvironments() {
        this.showNotification('Setting up environment templates...', 'success');
        console.log('Setting up environment templates...');
        // In real implementation, this would call the setup-env-templates.sh script
    }

    stopAllServices() {
        if (confirm('Are you sure you want to stop all running services?')) {
            this.showNotification('Stopping all services...', 'success');
            console.log('Stopping all services...');
            
            // Update all app statuses to stopped
            Object.values(this.apps).flat().forEach(app => {
                if (app.status === 'running') {
                    app.status = 'stopped';
                }
            });
            
            this.renderApplications();
            this.updateStats();
        }
    }

    // Show notification
    showNotification(message, type = 'success') {
        // Remove existing notifications
        document.querySelectorAll('.notification').forEach(n => n.remove());
        
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        
        document.body.appendChild(notification);
        
        // Show notification
        setTimeout(() => notification.classList.add('show'), 100);
        
        // Hide notification after 3 seconds
        setTimeout(() => {
            notification.classList.remove('show');
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }

    // Start polling for status updates
    startPolling() {
        setInterval(() => {
            // In a real implementation, this would poll the backend for status updates
            // For demo purposes, we'll randomly update some statuses
            if (Math.random() > 0.95) {
                const allApps = Object.values(this.apps).flat();
                const randomApp = allApps[Math.floor(Math.random() * allApps.length)];
                if (randomApp && randomApp.status === 'unknown') {
                    randomApp.status = Math.random() > 0.5 ? 'running' : 'stopped';
                    this.renderApplications();
                    this.updateStats();
                }
            }
        }, 5000);
    }
}

// Global functions for HTML onclick handlers
function showSection(section) {
    dashboard.showSection(section);
}

function refreshLogs() {
    dashboard.refreshLogs();
}

function checkDependencies() {
    dashboard.checkDependencies();
}

function setupEnvironments() {
    dashboard.setupEnvironments();
}

function stopAllServices() {
    dashboard.stopAllServices();
}

// Theme management
function initializeTheme() {
    const savedTheme = localStorage.getItem('theme') || 'light';
    document.documentElement.setAttribute('data-theme', savedTheme);
    updateThemeToggle(savedTheme);
}

function toggleTheme() {
    const currentTheme = document.documentElement.getAttribute('data-theme') || 'light';
    const newTheme = currentTheme === 'light' ? 'dark' : 'light';
    
    document.documentElement.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
    updateThemeToggle(newTheme);
}

function updateThemeToggle(theme) {
    const themeIcon = document.querySelector('.theme-icon');
    const themeText = document.getElementById('theme-text');
    
    if (theme === 'dark') {
        themeIcon.textContent = '☀️';
        themeText.textContent = 'Light';
        document.querySelector('.theme-toggle').title = 'Switch to Light Mode';
    } else {
        themeIcon.textContent = '🌙';
        themeText.textContent = 'Dark';
        document.querySelector('.theme-toggle').title = 'Switch to Dark Mode';
    }
}

// Initialize dashboard when page loads
let dashboard;
document.addEventListener('DOMContentLoaded', () => {
    initializeTheme();
    dashboard = new DeploymentDashboard();
});
