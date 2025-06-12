#!/bin/bash

# Simple OWASP ZAP Full Scan
# Minimal parameters for reliable scanning

set -e

# Configuration
TARGET_URL="${1:-http://localhost:3000}"
REPORT_DIR="./zap-reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MAX_DURATION="${2:-30}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔒 ZAP Simple Full Scan${NC}"
echo "========================"
echo -e "Target: ${GREEN}${TARGET_URL}${NC}"
echo -e "Max Duration: ${GREEN}${MAX_DURATION} minutes${NC}"
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

# Run ZAP full scan with minimal parameters
echo -e "${YELLOW}🚀 Running ZAP full scan...${NC}"
echo "This may take 15-45 minutes..."

START_TIME=$(date +%s)

docker run --rm \
    --network host \
    -v "$(pwd)/${REPORT_DIR}:/zap/wrk/" \
    zaproxy/zap-stable:latest \
    zap-full-scan.py \
    -t "${TARGET_URL}" \
    -m "${MAX_DURATION}" \
    -r "full_${TIMESTAMP}.html" \
    -J "full_${TIMESTAMP}.json"

SCAN_EXIT_CODE=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "=============================="
echo -e "${BLUE}⏱️  Duration: $((DURATION / 60))m $((DURATION % 60))s${NC}"

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
echo "  HTML: ${REPORT_DIR}/full_${TIMESTAMP}.html"
echo "  JSON: ${REPORT_DIR}/full_${TIMESTAMP}.json"

# Quick analysis if jq is available
if command -v jq > /dev/null && [ -f "${REPORT_DIR}/full_${TIMESTAMP}.json" ]; then
    echo ""
    echo -e "${BLUE}📊 Quick Analysis:${NC}"
    HIGH=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("High"))] | length' "${REPORT_DIR}/full_${TIMESTAMP}.json" 2>/dev/null || echo "0")
    MEDIUM=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("Medium"))] | length' "${REPORT_DIR}/full_${TIMESTAMP}.json" 2>/dev/null || echo "0")
    LOW=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("Low"))] | length' "${REPORT_DIR}/full_${TIMESTAMP}.json" 2>/dev/null || echo "0")
    
    echo "  🔴 High: $HIGH"
    echo "  🟡 Medium: $MEDIUM"
    echo "  🟢 Low: $LOW"
fi

echo ""

exit $SCAN_EXIT_CODE