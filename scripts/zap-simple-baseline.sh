#!/bin/bash

# Simple OWASP ZAP Baseline Scan
# Minimal parameters for reliable scanning

set -e

# Configuration
TARGET_URL="${1:-http://localhost:3000}"
REPORT_DIR="./zap-reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔒 ZAP Simple Baseline Scan${NC}"
echo "=============================="
echo -e "Target: ${GREEN}${TARGET_URL}${NC}"
echo ""

# Create reports directory
mkdir -p "${REPORT_DIR}"

# Check if target is accessible
echo -e "${YELLOW}🔍 Checking target...${NC}"
if curl -s --max-time 10 "${TARGET_URL}" > /dev/null; then
    echo -e "${GREEN}✅ Target accessible${NC}"
else
    echo -e "${RED}❌ Target not accessible${NC}"
    exit 1
fi

# Run ZAP baseline scan with minimal parameters
echo -e "${YELLOW}🚀 Running ZAP baseline scan...${NC}"

docker run --rm \
    --network host \
    -v "$(pwd)/${REPORT_DIR}:/zap/wrk/" \
    zaproxy/zap-stable:latest \
    zap-baseline.py \
    -t "${TARGET_URL}" \
    -r "baseline_${TIMESTAMP}.html" \
    -J "baseline_${TIMESTAMP}.json"

SCAN_EXIT_CODE=$?

echo ""
echo "=============================="
if [ $SCAN_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Scan completed successfully${NC}"
elif [ $SCAN_EXIT_CODE -eq 1 ]; then
    echo -e "${YELLOW}⚠️  Scan completed with warnings${NC}"
elif [ $SCAN_EXIT_CODE -eq 2 ]; then
    echo -e "${RED}🚨 Medium risk issues found${NC}"
elif [ $SCAN_EXIT_CODE -eq 3 ]; then
    echo -e "${RED}🚨 High risk issues found${NC}"
else
    echo -e "${RED}❌ Scan failed: exit code ${SCAN_EXIT_CODE}${NC}"
fi

echo ""
echo -e "${BLUE}📋 Reports:${NC}"
echo "  HTML: ${REPORT_DIR}/baseline_${TIMESTAMP}.html"
echo "  JSON: ${REPORT_DIR}/baseline_${TIMESTAMP}.json"
echo ""

exit $SCAN_EXIT_CODE