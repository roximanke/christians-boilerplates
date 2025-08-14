#!/bin/bash

# Environment Template Setup
# Creates .env template files for Docker Compose applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Setting up environment templates for Docker Compose applications...${NC}"

# Function to create .env template
create_env_template() {
    local app_dir=$1
    local app_name=$(basename "$app_dir")
    local compose_file="$app_dir/compose.yaml"
    local env_file="$app_dir/.env"
    
    if [ ! -f "$compose_file" ]; then
        return
    fi
    
    echo -e "${BLUE}📝 Processing $app_name...${NC}"
    
    # Extract environment variables from compose file
    env_vars=$(grep -o '\$[A-Z_][A-Z0-9_]*' "$compose_file" 2>/dev/null | sort -u | sed 's/\$//' || true)
    
    if [ -n "$env_vars" ]; then
        if [ ! -f "$env_file" ]; then
            echo "# Environment variables for $app_name" > "$env_file"
            echo "# Generated on $(date)" >> "$env_file"
            echo "# Please update these values before deployment" >> "$env_file"
            echo "" >> "$env_file"
            
            for var in $env_vars; do
                case $var in
                    *PASSWORD*|*PASS*)
                        echo "$var=changeme_secure_password_$(openssl rand -hex 8)" >> "$env_file"
                        ;;
                    *SECRET*|*KEY*)
                        echo "$var=changeme_secret_key_$(openssl rand -hex 16)" >> "$env_file"
                        ;;
                    *USER*|*USERNAME*)
                        echo "$var=${app_name}_user" >> "$env_file"
                        ;;
                    *DATABASE*|*DB*)
                        echo "$var=${app_name}_database" >> "$env_file"
                        ;;
                    *HOST*|*HOSTNAME*)
                        echo "$var=localhost" >> "$env_file"
                        ;;
                    *PORT*)
                        echo "$var=5432" >> "$env_file"
                        ;;
                    *EMAIL*|*MAIL*)
                        echo "$var=admin@example.com" >> "$env_file"
                        ;;
                    *DOMAIN*|*URL*)
                        echo "$var=https://your-domain.com" >> "$env_file"
                        ;;
                    *)
                        echo "$var=changeme" >> "$env_file"
                        ;;
                esac
            done
            
            echo -e "${GREEN}✅ Created $env_file${NC}"
        else
            echo -e "${YELLOW}⚠️  $env_file already exists, skipping${NC}"
        fi
    else
        echo -e "${YELLOW}ℹ️  No environment variables found for $app_name${NC}"
    fi
}

# Process all Docker Compose applications
find docker-compose -name "compose.yaml" -type f | while read -r compose_file; do
    app_dir=$(dirname "$compose_file")
    create_env_template "$app_dir"
done

echo
echo -e "${GREEN}🎉 Environment template setup completed!${NC}"
echo
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "1. Review and edit the .env files in each docker-compose directory"
echo "2. Update passwords, usernames, and other sensitive values"
echo "3. Run ./run.sh to deploy applications"
echo
echo -e "${YELLOW}💡 Security tip:${NC}"
echo "Consider adding *.env to your .gitignore to avoid committing secrets"
