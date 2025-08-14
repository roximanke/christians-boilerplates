#!/bin/bash

# Turnkey Deployment - Dependency Checker
# This script verifies all required tools are installed

set -e

echo "🔍 Checking dependencies for turnkey deployment..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

MISSING_DEPS=0

check_command() {
    local cmd=$1
    local name=$2
    local install_hint=$3
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "✅ ${GREEN}$name${NC} - $(command -v "$cmd")"
        if [[ "$cmd" == "docker" ]]; then
            echo "   Version: $(docker --version)"
        elif [[ "$cmd" == "ansible" ]]; then
            echo "   Version: $(ansible --version | head -n1)"
        elif [[ "$cmd" == "terraform" ]]; then
            echo "   Version: $(terraform --version | head -n1)"
        elif [[ "$cmd" == "kubectl" ]]; then
            echo "   Version: $(kubectl version --client --short 2>/dev/null || echo 'Client version available')"
        elif [[ "$cmd" == "helm" ]]; then
            echo "   Version: $(helm version --short 2>/dev/null || echo 'Helm available')"
        elif [[ "$cmd" == "vagrant" ]]; then
            echo "   Version: $(vagrant --version)"
        fi
    else
        echo -e "❌ ${RED}$name${NC} - Not found"
        echo -e "   ${YELLOW}Install hint: $install_hint${NC}"
        MISSING_DEPS=$((MISSING_DEPS + 1))
    fi
    echo
}

# Check core dependencies
check_command "docker" "Docker" "curl -fsSL https://get.docker.com | sh"
check_command "docker-compose" "Docker Compose" "Usually included with Docker Desktop"

# Check optional but recommended tools
echo "📦 Optional Tools (for specific deployments):"
echo "============================================="
check_command "ansible" "Ansible" "pip install ansible"
check_command "terraform" "Terraform" "Download from https://terraform.io/downloads"
check_command "kubectl" "Kubernetes CLI" "Download from https://kubernetes.io/docs/tasks/tools/"
check_command "helm" "Helm" "Download from https://helm.sh/docs/intro/install/"
check_command "vagrant" "Vagrant" "Download from https://vagrantup.com/downloads"

# Check Docker daemon
echo "🐳 Checking Docker daemon..."
if docker info &> /dev/null; then
    echo -e "✅ ${GREEN}Docker daemon is running${NC}"
else
    echo -e "❌ ${RED}Docker daemon is not running${NC}"
    echo -e "   ${YELLOW}Start Docker service: sudo systemctl start docker${NC}"
    MISSING_DEPS=$((MISSING_DEPS + 1))
fi
echo

# Summary
echo "📋 Summary:"
echo "==========="
if [ $MISSING_DEPS -eq 0 ]; then
    echo -e "🎉 ${GREEN}All core dependencies are satisfied!${NC}"
    echo "You can now run: ./run.sh"
    exit 0
else
    echo -e "⚠️  ${YELLOW}$MISSING_DEPS dependencies are missing${NC}"
    echo "Please install the missing tools before proceeding."
    exit 1
fi
