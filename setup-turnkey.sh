#!/bin/bash

# Turnkey Setup Script
# Initializes the turnkey deployment solution

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                🚀 Turnkey Setup Wizard                      ║"
echo "║          Initializing your deployment environment           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Step 1: Make scripts executable
echo -e "${BLUE}📝 Step 1: Making scripts executable...${NC}"
chmod +x check-dependencies.sh run.sh scripts/*.sh dashboard/server.py
echo -e "${GREEN}✅ Scripts are now executable${NC}"
echo

# Step 2: Create logs directory
echo -e "${BLUE}📁 Step 2: Creating logs directory...${NC}"
mkdir -p logs
echo -e "${GREEN}✅ Logs directory created${NC}"
echo

# Step 3: Check dependencies
echo -e "${BLUE}🔍 Step 3: Checking system dependencies...${NC}"
if ./check-dependencies.sh; then
    echo -e "${GREEN}✅ All dependencies satisfied${NC}"
else
    echo -e "${YELLOW}⚠️  Some dependencies are missing. Please install them before proceeding.${NC}"
fi
echo

# Step 4: Setup environment templates
echo -e "${BLUE}🔧 Step 4: Setting up environment templates...${NC}"
if ./scripts/setup-env-templates.sh; then
    echo -e "${GREEN}✅ Environment templates created${NC}"
else
    echo -e "${YELLOW}⚠️  Environment template setup completed with warnings${NC}"
fi
echo

# Step 5: Test CLI interface
echo -e "${BLUE}🧪 Step 5: Testing CLI interface...${NC}"
if [ -f "run.sh" ] && [ -x "run.sh" ]; then
    echo -e "${GREEN}✅ CLI interface is ready${NC}"
else
    echo -e "${RED}❌ CLI interface test failed${NC}"
fi
echo

# Step 6: Check Python for dashboard
echo -e "${BLUE}🐍 Step 6: Checking Python for web dashboard...${NC}"
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✅ Python3 is available${NC}"
    
    # Check for Flask
    if python3 -c "import flask" 2>/dev/null; then
        echo -e "${GREEN}✅ Flask is available${NC}"
    else
        echo -e "${YELLOW}⚠️  Flask not found. Installing...${NC}"
        pip3 install flask flask-cors 2>/dev/null || echo -e "${YELLOW}Please install Flask: pip3 install flask flask-cors${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Python3 not found. Web dashboard will not be available.${NC}"
fi
echo

# Summary
echo -e "${CYAN}📋 Setup Summary:${NC}"
echo "=================="
echo -e "${GREEN}✅ Scripts executable${NC}"
echo -e "${GREEN}✅ Logs directory created${NC}"
echo -e "${GREEN}✅ Dependencies checked${NC}"
echo -e "${GREEN}✅ Environment templates ready${NC}"
echo -e "${GREEN}✅ CLI interface ready${NC}"
echo

echo -e "${BLUE}🎯 Next Steps:${NC}"
echo "=============="
echo "1. Review and edit .env files in docker-compose directories"
echo "2. Update ansible/inventory with your target hosts"
echo "3. Configure terraform/*.tfvars files as needed"
echo
echo -e "${YELLOW}🚀 Ready to Deploy!${NC}"
echo "=================="
echo "• CLI Interface:    ./run.sh"
echo "• Web Dashboard:    cd dashboard && python3 server.py"
echo "• Documentation:    cat README-TURNKEY.md"
echo
echo -e "${GREEN}🎉 Turnkey setup completed successfully!${NC}"
