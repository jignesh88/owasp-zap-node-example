#!/bin/bash

# Test ZAP Commands Script
# This script tests ZAP command parameters and shows available options

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing ZAP Command Parameters${NC}"
echo "=================================="

ZAP_IMAGE="zaproxy/zap-stable:latest"

echo -e "${YELLOW}📥 Pulling ZAP image...${NC}"
docker pull "$ZAP_IMAGE" > /dev/null 2>&1 || echo "Image already exists"

echo ""
echo -e "${BLUE}🔍 ZAP Baseline Scan Help:${NC}"
echo "----------------------------------------"
docker run --rm "$ZAP_IMAGE" zap-baseline.py --help 2>/dev/null || echo "Command not available"

echo ""
echo -e "${BLUE}🔍 ZAP Full Scan Help:${NC}"
echo "----------------------------------------"
docker run --rm "$ZAP_IMAGE" zap-full-scan.py --help 2>/dev/null || echo "Command not available"

echo ""
echo -e "${BLUE}🧪 Testing Simple Commands:${NC}"
echo "----------------------------------------"

# Test baseline scan with minimal parameters
echo -e "${YELLOW}Testing baseline scan syntax...${NC}"
docker run --rm "$ZAP_IMAGE" zap-baseline.py -t http://example.com --dry-run 2>/dev/null && echo -e "${GREEN}✅ Baseline syntax OK${NC}" || echo -e "${RED}❌ Baseline syntax failed${NC}"

# Test full scan with minimal parameters  
echo -e "${YELLOW}Testing full scan syntax...${NC}"
docker run --rm "$ZAP_IMAGE" zap-full-scan.py -t http://example.com --dry-run 2>/dev/null && echo -e "${GREEN}✅ Full scan syntax OK${NC}" || echo -e "${RED}❌ Full scan syntax failed${NC}"

echo ""
echo -e "${BLUE}📋 Available ZAP Scripts:${NC}"
echo "----------------------------------------"
docker run --rm "$ZAP_IMAGE" ls /zap/ | grep -E "\.py$" | head -10

echo ""
echo -e "${BLUE}💡 Recommendations:${NC}"
echo "• Use minimal parameters for initial testing"
echo "• Check ZAP documentation for parameter syntax"
echo "• Test with --dry-run flag first"
echo ""