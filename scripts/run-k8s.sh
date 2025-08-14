#!/bin/bash

# Kubernetes Application Runner
# Deploys Kubernetes applications using Helm charts and manifests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [K8S] $1" | tee -a logs/deployment.log
}

# Check if application name is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Error: Application name is required${NC}"
    echo "Usage: $0 <application-name>"
    echo "Example: $0 portainer"
    exit 1
fi

APP_NAME="$1"
K8S_DIR="kubernetes/$APP_NAME"
HELM_DIR="$K8S_DIR/helm"
VALUES_FILE="$HELM_DIR/values.yaml"

# Verify application exists
if [ ! -d "$K8S_DIR" ]; then
    echo -e "${RED}❌ Error: Kubernetes application '$APP_NAME' not found${NC}"
    echo "Available applications:"
    find kubernetes -name "values.yaml" -type f | while read -r file; do
        app=$(basename "$(dirname "$(dirname "$file")")")
        echo "  • $app"
    done
    exit 1
fi

# Check kubectl availability
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ Error: kubectl is not installed${NC}"
    echo -e "${YELLOW}Install from: https://kubernetes.io/docs/tasks/tools/${NC}"
    exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Error: Cannot connect to Kubernetes cluster${NC}"
    echo -e "${YELLOW}💡 Make sure your kubeconfig is properly configured${NC}"
    exit 1
fi

echo -e "${BLUE}☸️  Deploying Kubernetes application: $APP_NAME${NC}"
log "Starting Kubernetes deployment of $APP_NAME"

# Show cluster info
echo -e "${BLUE}🔍 Cluster Information:${NC}"
kubectl cluster-info | head -3

# Check if Helm chart exists
if [ -f "$VALUES_FILE" ]; then
    echo -e "${BLUE}📦 Found Helm chart for $APP_NAME${NC}"
    
    # Check Helm availability
    if ! command -v helm &> /dev/null; then
        echo -e "${RED}❌ Error: Helm is not installed${NC}"
        echo -e "${YELLOW}Install from: https://helm.sh/docs/intro/install/${NC}"
        exit 1
    fi
    
    # Deploy with Helm
    deploy_with_helm
else
    # Look for YAML manifests
    MANIFEST_FILES=$(find "$K8S_DIR" -name "*.yaml" -type f | grep -v values.yaml | head -10)
    
    if [ -n "$MANIFEST_FILES" ]; then
        echo -e "${BLUE}📄 Found YAML manifests for $APP_NAME${NC}"
        deploy_with_kubectl
    else
        echo -e "${RED}❌ Error: No Helm chart or YAML manifests found for $APP_NAME${NC}"
        exit 1
    fi
fi

# Function to deploy with Helm
deploy_with_helm() {
    local namespace="${APP_NAME}"
    local release_name="${APP_NAME}"
    
    echo -e "${BLUE}🎯 Deploying with Helm...${NC}"
    log "Deploying $APP_NAME with Helm"
    
    # Show current values
    echo -e "${BLUE}📋 Current Helm values:${NC}"
    head -20 "$VALUES_FILE"
    echo
    
    # Ask for custom values
    echo -n "Use custom values file? [y/N]: "
    read -r custom_values_choice
    
    local values_arg="-f $VALUES_FILE"
    if [[ "$custom_values_choice" =~ ^[Yy]$ ]]; then
        echo -n "Enter path to custom values file: "
        read -r custom_values_file
        if [ -f "$custom_values_file" ]; then
            values_arg="-f $VALUES_FILE -f $custom_values_file"
        else
            echo -e "${YELLOW}⚠️  Custom values file not found, using default${NC}"
        fi
    fi
    
    # Check if release already exists
    if helm list -n "$namespace" | grep -q "$release_name"; then
        echo -e "${YELLOW}⚠️  Release $release_name already exists${NC}"
        echo -n "Upgrade existing release? [Y/n]: "
        read -r upgrade_choice
        
        if [[ ! "$upgrade_choice" =~ ^[Nn]$ ]]; then
            log "Upgrading existing Helm release $release_name"
            helm upgrade "$release_name" "$HELM_DIR" \
                $values_arg \
                --namespace "$namespace" \
                --wait \
                --timeout=300s
        else
            echo "Deployment cancelled."
            exit 0
        fi
    else
        # Install new release
        log "Installing new Helm release $release_name"
        helm install "$release_name" "$HELM_DIR" \
            $values_arg \
            --namespace "$namespace" \
            --create-namespace \
            --wait \
            --timeout=300s
    fi
    
    # Verify deployment
    verify_helm_deployment "$namespace" "$release_name"
}

# Function to deploy with kubectl
deploy_with_kubectl() {
    echo -e "${BLUE}🎯 Deploying with kubectl...${NC}"
    log "Deploying $APP_NAME with kubectl"
    
    # Show manifests to be applied
    echo -e "${BLUE}📄 Manifests to be applied:${NC}"
    echo "$MANIFEST_FILES"
    echo
    
    # Create namespace if specified
    if find "$K8S_DIR" -name "namespace.yaml" -type f | grep -q .; then
        echo -e "${BLUE}🏗️  Creating namespace...${NC}"
        kubectl apply -f "$K8S_DIR/namespace.yaml"
    fi
    
    # Apply all manifests
    echo -e "${BLUE}🚀 Applying manifests...${NC}"
    for manifest in $MANIFEST_FILES; do
        echo "Applying: $(basename "$manifest")"
        kubectl apply -f "$manifest"
    done
    
    # Wait for deployment
    echo -e "${BLUE}⏳ Waiting for deployment to be ready...${NC}"
    sleep 10
    
    # Verify deployment
    verify_kubectl_deployment
}

# Function to verify Helm deployment
verify_helm_deployment() {
    local namespace=$1
    local release_name=$2
    
    echo -e "${BLUE}🔍 Verifying Helm deployment...${NC}"
    
    if helm status "$release_name" -n "$namespace" | grep -q "STATUS: deployed"; then
        echo -e "${GREEN}✅ Helm deployment successful!${NC}"
        log "Successfully deployed $APP_NAME with Helm"
        
        # Show release info
        echo -e "${GREEN}📋 Release Information:${NC}"
        helm list -n "$namespace"
        
        # Show pods
        echo -e "${GREEN}🏃 Running Pods:${NC}"
        kubectl get pods -n "$namespace"
        
        # Show services
        echo -e "${GREEN}🌐 Services:${NC}"
        kubectl get services -n "$namespace"
        
    else
        echo -e "${RED}❌ Helm deployment failed!${NC}"
        log "Failed to deploy $APP_NAME with Helm"
        echo -e "${YELLOW}📄 Release status:${NC}"
        helm status "$release_name" -n "$namespace"
        exit 1
    fi
}

# Function to verify kubectl deployment
verify_kubectl_deployment() {
    echo -e "${BLUE}🔍 Verifying kubectl deployment...${NC}"
    
    # Check pods
    echo -e "${GREEN}🏃 Pods:${NC}"
    kubectl get pods -l app="$APP_NAME" 2>/dev/null || kubectl get pods -A | grep "$APP_NAME" || echo "No pods found with app=$APP_NAME label"
    
    # Check services
    echo -e "${GREEN}🌐 Services:${NC}"
    kubectl get services -A | grep "$APP_NAME" || echo "No services found for $APP_NAME"
    
    # Check deployments
    echo -e "${GREEN}🚀 Deployments:${NC}"
    kubectl get deployments -A | grep "$APP_NAME" || echo "No deployments found for $APP_NAME"
    
    echo -e "${GREEN}✅ Kubectl deployment completed!${NC}"
    log "Successfully deployed $APP_NAME with kubectl"
}

# Show access information
show_access_info() {
    echo
    echo -e "${GREEN}🌐 Access Information:${NC}"
    echo "================================"
    
    # Get services with external access
    services=$(kubectl get services -A -o wide | grep -E "(LoadBalancer|NodePort)" | grep "$APP_NAME" || true)
    
    if [ -n "$services" ]; then
        echo "$services"
        echo
        echo -e "${YELLOW}💡 Access your application using the external IPs/ports shown above${NC}"
    else
        echo "No external services found. You may need to:"
        echo "  • Set up port forwarding: kubectl port-forward service/$APP_NAME 8080:80"
        echo "  • Configure ingress for external access"
        echo "  • Check service configuration"
    fi
}

# Main execution continues...
echo
echo -n "Show access information? [Y/n]: "
read -r access_choice
if [[ ! "$access_choice" =~ ^[Nn]$ ]]; then
    show_access_info
fi

# Show logs option
echo
echo -n "View recent logs? [y/N]: "
read -r logs_choice
if [[ "$logs_choice" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}📄 Recent logs:${NC}"
    kubectl logs -l app="$APP_NAME" --tail=20 2>/dev/null || \
    kubectl logs -A -l app="$APP_NAME" --tail=20 2>/dev/null || \
    echo "Could not retrieve logs. Try: kubectl logs -n <namespace> <pod-name>"
fi

log "Kubernetes deployment completed for $APP_NAME"
