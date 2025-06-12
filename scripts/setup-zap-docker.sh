#!/bin/bash

# Setup OWASP ZAP Docker Script
# This script pulls the correct ZAP Docker image and verifies it works

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔒 OWASP ZAP Docker Setup${NC}"
echo "==============================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

echo -e "${YELLOW}📥 Pulling OWASP ZAP Docker image...${NC}"

# Try different ZAP image names to find the correct one
ZAP_IMAGES=(
    "zaproxy/zap-stable:latest"
    "zaproxy/zap-weekly:latest"
    "owasp/zap2docker-stable:latest"
    "softwaresecurityproject/zap-stable:latest"
)

ZAP_IMAGE=""
for image in "${ZAP_IMAGES[@]}"; do
    echo -e "${YELLOW}Trying: ${image}${NC}"
    if docker pull "$image" > /dev/null 2>&1; then
        ZAP_IMAGE="$image"
        echo -e "${GREEN}✅ Successfully pulled: ${image}${NC}"
        break
    else
        echo -e "${RED}❌ Failed to pull: ${image}${NC}"
    fi
done

if [ -z "$ZAP_IMAGE" ]; then
    echo -e "${RED}❌ Could not pull any ZAP Docker image.${NC}"
    echo "Please check your internet connection and try again."
    exit 1
fi

# Test the ZAP image
echo -e "${YELLOW}🧪 Testing ZAP Docker image...${NC}"
if docker run --rm "$ZAP_IMAGE" zap-baseline.py --help > /dev/null 2>&1; then
    echo -e "${GREEN}✅ ZAP baseline scan command works${NC}"
else
    echo -e "${YELLOW}⚠️  ZAP baseline command test failed, but image is available${NC}"
fi

if docker run --rm "$ZAP_IMAGE" zap-full-scan.py --help > /dev/null 2>&1; then
    echo -e "${GREEN}✅ ZAP full scan command works${NC}"
else
    echo -e "${YELLOW}⚠️  ZAP full scan command test failed, but image is available${NC}"
fi

# Update docker-compose and scripts if needed
if [ "$ZAP_IMAGE" != "zaproxy/zap-stable:latest" ]; then
    echo -e "${YELLOW}📝 Updating scripts to use: ${ZAP_IMAGE}${NC}"
    
    # Update docker-compose.yml
    if [ -f "docker-compose.yml" ]; then
        sed -i.bak "s|zaproxy/zap-stable:latest|${ZAP_IMAGE}|g" docker-compose.yml
        echo -e "${GREEN}✅ Updated docker-compose.yml${NC}"
    fi
    
    # Update ZAP scripts
    for script in scripts/zap-*.sh; do
        if [ -f "$script" ]; then
            sed -i.bak "s|zaproxy/zap-stable:latest|${ZAP_IMAGE}|g" "$script"
            echo -e "${GREEN}✅ Updated $script${NC}"
        fi
    done
    
    # Update README
    if [ -f "README.md" ]; then
        sed -i.bak "s|zaproxy/zap-stable:latest|${ZAP_IMAGE}|g" README.md
        echo -e "${GREEN}✅ Updated README.md${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🎉 ZAP Docker Setup Complete!${NC}"
echo "================================"
echo -e "Using ZAP Image: ${GREEN}${ZAP_IMAGE}${NC}"
echo ""
echo -e "${BLUE}📚 Available Commands:${NC}"
echo "  Start ZAP daemon:     docker-compose up -d zap"
echo "  ZAP Web UI:          http://localhost:8080"
echo "  Run baseline scan:   ./scripts/zap-baseline-scan.sh"
echo "  Run full scan:       ./scripts/zap-full-scan.sh"
echo ""
echo -e "${BLUE}🔧 Manual ZAP Commands:${NC}"
echo "  Baseline: docker run --rm --network host -v \$(pwd)/zap-reports:/zap/wrk ${ZAP_IMAGE} zap-baseline.py -t http://localhost:3000"
echo "  Full:     docker run --rm --network host -v \$(pwd)/zap-reports:/zap/wrk ${ZAP_IMAGE} zap-full-scan.py -t http://localhost:3000"
echo ""