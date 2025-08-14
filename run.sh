#!/bin/bash

# Turnkey Deployment - Main CLI Tool
# Central command-line interface for deploying all applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Create logs directory
mkdir -p logs

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a logs/deployment.log
}

# Error handling
handle_error() {
    log "❌ Error occurred in $1"
    echo -e "${RED}Deployment failed. Check logs/deployment.log for details.${NC}"
    exit 1
}

# Banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    🚀 Turnkey Deployment                     ║"
    echo "║              Christian's Boilerplates Manager               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Show available applications
show_apps() {
    echo -e "${BLUE}📦 Available Applications:${NC}"
    echo "=========================="
    echo
    
    echo -e "${GREEN}🐳 Docker Compose Applications:${NC}"
    find docker-compose -name "compose.yaml" -type f | while read -r file; do
        app_name=$(basename "$(dirname "$file")")
        echo "  • $app_name"
    done
    echo
    
    echo -e "${GREEN}🔧 Ansible Playbooks:${NC}"
    find ansible -name "*.yaml" -type f | while read -r file; do
        playbook_name=$(basename "$file" .yaml)
        echo "  • $playbook_name"
    done
    echo
    
    echo -e "${GREEN}☸️  Kubernetes Applications:${NC}"
    find kubernetes -name "values.yaml" -type f | while read -r file; do
        app_name=$(basename "$(dirname "$(dirname "$file")")")
        echo "  • $app_name"
    done
    echo
    
    echo -e "${GREEN}🏗️  Terraform Configurations:${NC}"
    find terraform -name "*.tf" -type f | while read -r file; do
        config_name=$(basename "$(dirname "$file")")
        echo "  • $config_name"
    done
    echo
    
    echo -e "${GREEN}📦 Vagrant Boxes:${NC}"
    find vagrant -name "Vagrantfile" -type f | while read -r file; do
        box_name=$(basename "$(dirname "$file")")
        echo "  • $box_name"
    done
    echo
}

# Main menu
show_menu() {
    echo -e "${YELLOW}🎯 What would you like to deploy?${NC}"
    echo "================================"
    echo "1) 🐳 Docker Compose Application"
    echo "2) 🔧 Ansible Playbook"
    echo "3) ☸️  Kubernetes Application"
    echo "4) 🏗️  Terraform Configuration"
    echo "5) 📦 Vagrant Box"
    echo "6) 📋 List All Available Apps"
    echo "7) 🔍 Check Dependencies"
    echo "8) 📊 Show Status"
    echo "9) 🛑 Stop All Services"
    echo "0) ❌ Exit"
    echo
    echo -n "Enter your choice [0-9]: "
}

# Docker menu
docker_menu() {
    echo -e "${BLUE}🐳 Docker Compose Applications:${NC}"
    echo "==============================="
    
    apps=()
    while IFS= read -r -d '' file; do
        app_name=$(basename "$(dirname "$file")")
        apps+=("$app_name")
        echo "${#apps[@]}) $app_name"
    done < <(find docker-compose -name "compose.yaml" -type f -print0 | sort -z)
    
    echo "0) Back to main menu"
    echo
    echo -n "Select application to deploy: "
    read -r choice
    
    if [[ "$choice" == "0" ]]; then
        return
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#apps[@]}" ] && [ "$choice" -gt 0 ]; then
        selected_app="${apps[$((choice-1))]}"
        log "Deploying Docker application: $selected_app"
        ./scripts/run-docker.sh "$selected_app" || handle_error "Docker deployment"
    else
        echo -e "${RED}Invalid selection${NC}"
    fi
}

# Ansible menu
ansible_menu() {
    echo -e "${BLUE}🔧 Ansible Playbooks:${NC}"
    echo "===================="
    
    playbooks=()
    while IFS= read -r -d '' file; do
        playbook_name=$(basename "$file")
        playbooks+=("$file")
        echo "${#playbooks[@]}) $playbook_name"
    done < <(find ansible -name "*.yaml" -type f -print0 | sort -z)
    
    echo "0) Back to main menu"
    echo
    echo -n "Select playbook to run: "
    read -r choice
    
    if [[ "$choice" == "0" ]]; then
        return
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#playbooks[@]}" ] && [ "$choice" -gt 0 ]; then
        selected_playbook="${playbooks[$((choice-1))]}"
        log "Running Ansible playbook: $selected_playbook"
        ./scripts/run-ansible.sh "$selected_playbook" || handle_error "Ansible deployment"
    else
        echo -e "${RED}Invalid selection${NC}"
    fi
}

# Kubernetes menu
k8s_menu() {
    echo -e "${BLUE}☸️  Kubernetes Applications:${NC}"
    echo "=========================="
    
    apps=()
    while IFS= read -r -d '' file; do
        app_name=$(basename "$(dirname "$(dirname "$file")")")
        apps+=("$app_name")
        echo "${#apps[@]}) $app_name"
    done < <(find kubernetes -name "values.yaml" -type f -print0 | sort -z)
    
    echo "0) Back to main menu"
    echo
    echo -n "Select application to deploy: "
    read -r choice
    
    if [[ "$choice" == "0" ]]; then
        return
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#apps[@]}" ] && [ "$choice" -gt 0 ]; then
        selected_app="${apps[$((choice-1))]}"
        log "Deploying Kubernetes application: $selected_app"
        ./scripts/run-k8s.sh "$selected_app" || handle_error "Kubernetes deployment"
    else
        echo -e "${RED}Invalid selection${NC}"
    fi
}

# Terraform menu
terraform_menu() {
    echo -e "${BLUE}🏗️  Terraform Configurations:${NC}"
    echo "============================"
    
    configs=()
    while IFS= read -r -d '' dir; do
        config_name=$(basename "$dir")
        configs+=("$config_name")
        echo "${#configs[@]}) $config_name"
    done < <(find terraform -name "*.tf" -type f -exec dirname {} \; | sort -u | tr '\n' '\0')
    
    echo "0) Back to main menu"
    echo
    echo -n "Select configuration to deploy: "
    read -r choice
    
    if [[ "$choice" == "0" ]]; then
        return
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#configs[@]}" ] && [ "$choice" -gt 0 ]; then
        selected_config="${configs[$((choice-1))]}"
        log "Deploying Terraform configuration: $selected_config"
        ./scripts/run-terraform.sh "$selected_config" || handle_error "Terraform deployment"
    else
        echo -e "${RED}Invalid selection${NC}"
    fi
}

# Show status
show_status() {
    echo -e "${BLUE}📊 System Status:${NC}"
    echo "================"
    echo
    
    echo -e "${GREEN}🐳 Docker Containers:${NC}"
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No containers running"
    else
        echo "Docker not available"
    fi
    echo
    
    echo -e "${GREEN}📁 Recent Logs:${NC}"
    if [ -f logs/deployment.log ]; then
        tail -n 5 logs/deployment.log
    else
        echo "No deployment logs found"
    fi
}

# Stop all services
stop_all() {
    echo -e "${YELLOW}🛑 Stopping all services...${NC}"
    log "Stopping all Docker containers"
    
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        # Stop all running containers
        running_containers=$(docker ps -q)
        if [ -n "$running_containers" ]; then
            docker stop $running_containers
            echo -e "${GREEN}✅ All Docker containers stopped${NC}"
        else
            echo "No running containers found"
        fi
    else
        echo "Docker not available"
    fi
}

# Main execution
main() {
    show_banner
    
    # Check if scripts directory exists
    if [ ! -d "scripts" ]; then
        echo -e "${YELLOW}⚠️  Scripts directory not found. Creating deployment scripts...${NC}"
        # This will be handled by creating the scripts in the next steps
    fi
    
    while true; do
        echo
        show_menu
        read -r choice
        
        case $choice in
            1) docker_menu ;;
            2) ansible_menu ;;
            3) k8s_menu ;;
            4) terraform_menu ;;
            5) echo -e "${YELLOW}Vagrant deployment coming soon...${NC}" ;;
            6) show_apps ;;
            7) ./check-dependencies.sh ;;
            8) show_status ;;
            9) stop_all ;;
            0) 
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                ;;
        esac
        
        echo
        echo -n "Press Enter to continue..."
        read -r
    done
}

# Run main function
main "$@"
