#!/bin/bash

# Terraform Configuration Runner
# Deploys infrastructure using Terraform configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TERRAFORM] $1" | tee -a logs/deployment.log
}

# Check if configuration name is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Error: Configuration name is required${NC}"
    echo "Usage: $0 <configuration-name>"
    echo "Example: $0 proxmox"
    exit 1
fi

CONFIG_NAME="$1"
TERRAFORM_DIR="terraform/$CONFIG_NAME"

# Verify configuration exists
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo -e "${RED}❌ Error: Terraform configuration '$CONFIG_NAME' not found${NC}"
    echo "Available configurations:"
    find terraform -name "*.tf" -type f -exec dirname {} \; | sort -u | while read -r dir; do
        config=$(basename "$dir")
        echo "  • $config"
    done
    exit 1
fi

# Check Terraform availability
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Error: Terraform is not installed${NC}"
    echo -e "${YELLOW}Install from: https://terraform.io/downloads${NC}"
    exit 1
fi

echo -e "${BLUE}🏗️  Deploying Terraform configuration: $CONFIG_NAME${NC}"
log "Starting Terraform deployment of $CONFIG_NAME"

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Check for required files
if [ ! -f "*.tf" ] && [ -z "$(ls *.tf 2>/dev/null)" ]; then
    echo -e "${RED}❌ Error: No .tf files found in $TERRAFORM_DIR${NC}"
    exit 1
fi

# Show configuration files
echo -e "${BLUE}📄 Configuration files:${NC}"
ls -la *.tf

# Check for variables file
TFVARS_FILE=""
if [ -f "terraform.tfvars" ]; then
    TFVARS_FILE="terraform.tfvars"
elif [ -f "*.auto.tfvars" ] && [ -n "$(ls *.auto.tfvars 2>/dev/null)" ]; then
    TFVARS_FILE=$(ls *.auto.tfvars | head -1)
fi

if [ -z "$TFVARS_FILE" ]; then
    echo -e "${YELLOW}⚠️  No variables file found${NC}"
    
    # Check if variables are defined in .tf files
    if grep -q "variable " *.tf; then
        echo -e "${YELLOW}📝 Variables found in configuration. Creating template...${NC}"
        
        # Extract variable definitions
        grep -h "variable " *.tf | sed 's/variable "//' | sed 's/" {//' > temp_vars.txt
        
        if [ -s temp_vars.txt ]; then
            echo "# Terraform variables for $CONFIG_NAME" > terraform.tfvars
            echo "# Generated on $(date)" >> terraform.tfvars
            echo "" >> terraform.tfvars
            
            while read -r var_name; do
                case $var_name in
                    *password*|*secret*|*key*)
                        echo "$var_name = \"changeme_secure_value\"" >> terraform.tfvars
                        ;;
                    *host*|*server*)
                        echo "$var_name = \"your-server-address\"" >> terraform.tfvars
                        ;;
                    *user*)
                        echo "$var_name = \"your-username\"" >> terraform.tfvars
                        ;;
                    *)
                        echo "$var_name = \"changeme\"" >> terraform.tfvars
                        ;;
                esac
            done < temp_vars.txt
            
            rm temp_vars.txt
            TFVARS_FILE="terraform.tfvars"
            
            echo -e "${YELLOW}📝 Please edit $TFVARS_FILE with your actual values${NC}"
            echo
            echo -n "Continue with template values? [y/N]: "
            read -r continue_choice
            
            if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
                echo "Deployment cancelled. Please edit $TFVARS_FILE and run again."
                exit 0
            fi
        fi
    fi
fi

# Initialize Terraform
echo -e "${BLUE}🔧 Initializing Terraform...${NC}"
log "Initializing Terraform in $TERRAFORM_DIR"

if ! terraform init; then
    echo -e "${RED}❌ Terraform initialization failed${NC}"
    log "Terraform initialization failed for $CONFIG_NAME"
    exit 1
fi

echo -e "${GREEN}✅ Terraform initialized successfully${NC}"

# Validate configuration
echo -e "${BLUE}🔍 Validating configuration...${NC}"
if ! terraform validate; then
    echo -e "${RED}❌ Terraform validation failed${NC}"
    log "Terraform validation failed for $CONFIG_NAME"
    exit 1
fi

echo -e "${GREEN}✅ Configuration is valid${NC}"

# Plan deployment
echo -e "${BLUE}📋 Creating deployment plan...${NC}"
log "Creating Terraform plan for $CONFIG_NAME"

PLAN_ARGS=""
if [ -n "$TFVARS_FILE" ]; then
    PLAN_ARGS="-var-file=$TFVARS_FILE"
fi

if ! terraform plan $PLAN_ARGS -out=tfplan; then
    echo -e "${RED}❌ Terraform plan failed${NC}"
    log "Terraform plan failed for $CONFIG_NAME"
    exit 1
fi

echo -e "${GREEN}✅ Plan created successfully${NC}"

# Show plan summary
echo -e "${BLUE}📊 Plan Summary:${NC}"
terraform show -no-color tfplan | head -50
echo

# Confirm deployment
echo -e "${YELLOW}⚠️  This will create/modify/destroy infrastructure!${NC}"
echo -n "Proceed with deployment? [y/N]: "
read -r deploy_choice

if [[ ! "$deploy_choice" =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    rm -f tfplan
    exit 0
fi

# Apply configuration
echo -e "${BLUE}🚀 Applying configuration...${NC}"
log "Applying Terraform configuration for $CONFIG_NAME"

if terraform apply tfplan; then
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
    log "Successfully deployed $CONFIG_NAME with Terraform"
    
    # Show outputs
    echo -e "${GREEN}📋 Terraform Outputs:${NC}"
    terraform output 2>/dev/null || echo "No outputs defined"
    
    # Show state summary
    echo -e "${GREEN}📊 Infrastructure Summary:${NC}"
    terraform state list 2>/dev/null | head -20 || echo "Could not list state"
    
    # Save deployment info
    echo "Deployment completed at $(date)" > deployment-info.txt
    echo "Configuration: $CONFIG_NAME" >> deployment-info.txt
    echo "Terraform version: $(terraform version | head -1)" >> deployment-info.txt
    
else
    echo -e "${RED}❌ Deployment failed!${NC}"
    log "Failed to deploy $CONFIG_NAME with Terraform"
    
    echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
    echo "  • Check your variables in $TFVARS_FILE"
    echo "  • Verify provider credentials"
    echo "  • Review the error messages above"
    echo "  • Check terraform.log for detailed errors"
    
    exit 1
fi

# Cleanup
rm -f tfplan

# Show management commands
echo
echo -e "${BLUE}🔧 Management Commands:${NC}"
echo "================================"
echo "View state:     terraform state list"
echo "Show outputs:   terraform output"
echo "Plan changes:   terraform plan"
echo "Destroy:        terraform destroy"
echo

# Ask about state management
echo -n "Show current state? [y/N]: "
read -r state_choice
if [[ "$state_choice" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}📊 Current State:${NC}"
    terraform state list
fi

log "Terraform deployment completed for $CONFIG_NAME"
