#!/bin/bash

# Docker Compose Application Runner
# Deploys Docker Compose applications with proper environment handling

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DOCKER] $1" | tee -a logs/deployment.log
}

# Check if application name is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Error: Application name is required${NC}"
    echo "Usage: $0 <application-name>"
    echo "Example: $0 grafana"
    exit 1
fi

APP_NAME="$1"
COMPOSE_DIR="docker-compose/$APP_NAME"
COMPOSE_FILE="$COMPOSE_DIR/compose.yaml"
ENV_FILE="$COMPOSE_DIR/.env"

# Verify application exists
if [ ! -d "$COMPOSE_DIR" ]; then
    echo -e "${RED}❌ Error: Application '$APP_NAME' not found${NC}"
    echo "Available applications:"
    find docker-compose -name "compose.yaml" -type f | while read -r file; do
        app=$(basename "$(dirname "$file")")
        echo "  • $app"
    done
    exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}❌ Error: compose.yaml not found for '$APP_NAME'${NC}"
    exit 1
fi

# Check Docker availability
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Error: Docker is not installed${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Error: Docker daemon is not running${NC}"
    exit 1
fi

# Check for environment file and create if needed
if [ ! -f "$ENV_FILE" ]; then
    log "Creating environment file for $APP_NAME"
    
    # Extract environment variables from compose file
    env_vars=$(grep -o '\$[A-Z_][A-Z0-9_]*' "$COMPOSE_FILE" | sort -u | sed 's/\$//')
    
    if [ -n "$env_vars" ]; then
        echo -e "${YELLOW}⚠️  Environment file not found. Creating template...${NC}"
        echo "# Environment variables for $APP_NAME" > "$ENV_FILE"
        echo "# Generated on $(date)" >> "$ENV_FILE"
        echo "" >> "$ENV_FILE"
        
        for var in $env_vars; do
            case $var in
                *PASSWORD*)
                    echo "$var=changeme_secure_password" >> "$ENV_FILE"
                    ;;
                *USER*)
                    echo "$var=${APP_NAME}_user" >> "$ENV_FILE"
                    ;;
                *DATABASE*)
                    echo "$var=${APP_NAME}_db" >> "$ENV_FILE"
                    ;;
                *HOST*)
                    echo "$var=localhost" >> "$ENV_FILE"
                    ;;
                *)
                    echo "$var=changeme" >> "$ENV_FILE"
                    ;;
            esac
        done
        
        echo -e "${YELLOW}📝 Please edit $ENV_FILE with your desired values${NC}"
        echo -e "${YELLOW}   Current template values are placeholders${NC}"
        echo
        echo -n "Continue with template values? [y/N]: "
        read -r continue_choice
        
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            echo "Deployment cancelled. Please edit $ENV_FILE and run again."
            exit 0
        fi
    fi
fi

echo -e "${BLUE}🐳 Deploying Docker application: $APP_NAME${NC}"
log "Starting deployment of $APP_NAME"

# Show current status
echo -e "${BLUE}📊 Current status:${NC}"
cd "$COMPOSE_DIR"
if docker-compose ps 2>/dev/null | grep -q "$APP_NAME"; then
    echo "Application is currently running:"
    docker-compose ps
    echo
    echo -n "Stop and redeploy? [y/N]: "
    read -r redeploy_choice
    
    if [[ "$redeploy_choice" =~ ^[Yy]$ ]]; then
        log "Stopping existing $APP_NAME containers"
        docker-compose down
    else
        echo "Deployment cancelled."
        exit 0
    fi
fi

# Deploy the application
log "Pulling latest images for $APP_NAME"
echo -e "${BLUE}📥 Pulling latest images...${NC}"
docker-compose pull || log "Warning: Some images could not be pulled"

log "Starting $APP_NAME containers"
echo -e "${BLUE}🚀 Starting containers...${NC}"
docker-compose up -d

# Verify deployment
sleep 5
echo -e "${BLUE}🔍 Verifying deployment...${NC}"
if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    log "Successfully deployed $APP_NAME"
    
    echo
    echo -e "${GREEN}📋 Container Status:${NC}"
    docker-compose ps
    
    # Show access information
    echo
    echo -e "${GREEN}🌐 Access Information:${NC}"
    ports=$(docker-compose ps --format "table {{.Name}}\t{{.Ports}}" | grep -v "NAME" | grep -v "^$")
    if [ -n "$ports" ]; then
        echo "$ports"
        echo
        echo -e "${YELLOW}💡 Access your application at the ports shown above${NC}"
        echo -e "${YELLOW}   Example: http://localhost:PORT${NC}"
    fi
    
    # Show logs option
    echo
    echo -n "View logs? [y/N]: "
    read -r logs_choice
    if [[ "$logs_choice" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}📄 Recent logs:${NC}"
        docker-compose logs --tail=20
    fi
    
else
    echo -e "${RED}❌ Deployment failed!${NC}"
    log "Failed to deploy $APP_NAME"
    echo -e "${YELLOW}📄 Container logs:${NC}"
    docker-compose logs --tail=20
    exit 1
fi

log "Docker deployment completed for $APP_NAME"
