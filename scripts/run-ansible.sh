#!/bin/bash

# Ansible Playbook Runner
# Executes Ansible playbooks with proper inventory and error handling

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ANSIBLE] $1" | tee -a logs/deployment.log
}

# Check if playbook path is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Error: Playbook path is required${NC}"
    echo "Usage: $0 <playbook-path>"
    echo "Example: $0 ansible/docker/inst-docker-ubuntu.yaml"
    exit 1
fi

PLAYBOOK_PATH="$1"
PLAYBOOK_NAME=$(basename "$PLAYBOOK_PATH" .yaml)

# Verify playbook exists
if [ ! -f "$PLAYBOOK_PATH" ]; then
    echo -e "${RED}❌ Error: Playbook '$PLAYBOOK_PATH' not found${NC}"
    echo "Available playbooks:"
    find ansible -name "*.yaml" -type f | sort
    exit 1
fi

# Check Ansible availability
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${RED}❌ Error: Ansible is not installed${NC}"
    echo -e "${YELLOW}Install with: pip install ansible${NC}"
    exit 1
fi

# Create default inventory if it doesn't exist
INVENTORY_FILE="ansible/inventory"
if [ ! -f "$INVENTORY_FILE" ]; then
    echo -e "${YELLOW}⚠️  Creating default inventory file...${NC}"
    mkdir -p ansible
    cat > "$INVENTORY_FILE" << EOF
# Ansible Inventory File
# Edit this file to match your infrastructure

[local]
localhost ansible_connection=local

[servers]
# Add your servers here
# example-server ansible_host=192.168.1.100 ansible_user=ubuntu

[all:vars]
# Global variables
ansible_python_interpreter=/usr/bin/python3
EOF
    echo -e "${YELLOW}📝 Please edit $INVENTORY_FILE with your target hosts${NC}"
fi

# Check for secrets file if playbook references it
if grep -q "secrets.yaml" "$PLAYBOOK_PATH"; then
    SECRETS_DIR=$(dirname "$PLAYBOOK_PATH")
    SECRETS_FILE="$SECRETS_DIR/secrets.yaml"
    
    if [ ! -f "$SECRETS_FILE" ]; then
        echo -e "${YELLOW}⚠️  Creating secrets template...${NC}"
        cat > "$SECRETS_FILE" << EOF
# Secrets file for $(basename "$PLAYBOOK_PATH")
# Generated on $(date)
# 
# IMPORTANT: Add this file to .gitignore to avoid committing secrets!

# Example secrets (replace with actual values):
# checkmk_server: "https://your-checkmk-server"
# checkmk_username: "automation"
# checkmk_password: "your-secure-password"
# checkmk_site: "cmk"

# Add your actual secrets here
EOF
        echo -e "${YELLOW}📝 Please edit $SECRETS_FILE with your actual secrets${NC}"
        echo -e "${RED}⚠️  Remember to add secrets.yaml to .gitignore!${NC}"
    fi
fi

echo -e "${BLUE}🔧 Running Ansible playbook: $PLAYBOOK_NAME${NC}"
log "Starting Ansible playbook: $PLAYBOOK_PATH"

# Validate playbook syntax
echo -e "${BLUE}🔍 Validating playbook syntax...${NC}"
if ! ansible-playbook --syntax-check "$PLAYBOOK_PATH" -i "$INVENTORY_FILE" &>/dev/null; then
    echo -e "${RED}❌ Playbook syntax validation failed${NC}"
    ansible-playbook --syntax-check "$PLAYBOOK_PATH" -i "$INVENTORY_FILE"
    exit 1
fi

echo -e "${GREEN}✅ Playbook syntax is valid${NC}"

# Show inventory
echo -e "${BLUE}📋 Using inventory: $INVENTORY_FILE${NC}"
echo -e "${BLUE}🎯 Target hosts:${NC}"
ansible-inventory -i "$INVENTORY_FILE" --list --yaml 2>/dev/null | head -20 || echo "Could not display inventory"

# Prompt for target hosts
echo
echo -e "${YELLOW}🎯 Specify target hosts:${NC}"
echo "1) localhost (run locally)"
echo "2) all (run on all inventory hosts)"
echo "3) servers (run on servers group)"
echo "4) custom (specify manually)"
echo
echo -n "Select target [1-4]: "
read -r target_choice

case $target_choice in
    1) TARGET_HOSTS="localhost" ;;
    2) TARGET_HOSTS="all" ;;
    3) TARGET_HOSTS="servers" ;;
    4) 
        echo -n "Enter target hosts/groups: "
        read -r TARGET_HOSTS
        ;;
    *)
        echo -e "${YELLOW}Using default: localhost${NC}"
        TARGET_HOSTS="localhost"
        ;;
esac

# Dry run option
echo
echo -n "Perform dry run first? [Y/n]: "
read -r dry_run_choice

if [[ ! "$dry_run_choice" =~ ^[Nn]$ ]]; then
    echo -e "${BLUE}🧪 Performing dry run...${NC}"
    log "Performing dry run for $PLAYBOOK_PATH"
    
    if ansible-playbook "$PLAYBOOK_PATH" \
        -i "$INVENTORY_FILE" \
        --limit "$TARGET_HOSTS" \
        --check \
        --diff; then
        echo -e "${GREEN}✅ Dry run completed successfully${NC}"
        echo
        echo -n "Proceed with actual execution? [Y/n]: "
        read -r proceed_choice
        
        if [[ "$proceed_choice" =~ ^[Nn]$ ]]; then
            echo "Execution cancelled."
            exit 0
        fi
    else
        echo -e "${RED}❌ Dry run failed${NC}"
        exit 1
    fi
fi

# Execute playbook
echo -e "${BLUE}🚀 Executing playbook...${NC}"
log "Executing playbook: $PLAYBOOK_PATH on $TARGET_HOSTS"

# Build ansible-playbook command
ANSIBLE_CMD="ansible-playbook $PLAYBOOK_PATH -i $INVENTORY_FILE --limit $TARGET_HOSTS"

# Add verbosity for better logging
ANSIBLE_CMD="$ANSIBLE_CMD -v"

# Execute the playbook
if eval "$ANSIBLE_CMD"; then
    echo -e "${GREEN}✅ Playbook execution completed successfully!${NC}"
    log "Successfully executed $PLAYBOOK_PATH"
    
    # Show summary
    echo
    echo -e "${GREEN}📋 Execution Summary:${NC}"
    echo "  Playbook: $PLAYBOOK_NAME"
    echo "  Targets: $TARGET_HOSTS"
    echo "  Status: Success"
    
else
    echo -e "${RED}❌ Playbook execution failed!${NC}"
    log "Failed to execute $PLAYBOOK_PATH"
    echo
    echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
    echo "  • Check inventory file: $INVENTORY_FILE"
    echo "  • Verify SSH connectivity to target hosts"
    echo "  • Check playbook variables and secrets"
    echo "  • Review logs above for specific errors"
    exit 1
fi

log "Ansible playbook execution completed for $PLAYBOOK_PATH"
