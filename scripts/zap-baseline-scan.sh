#!/bin/bash

# OWASP ZAP Baseline Scan Script
# This script runs a baseline security scan against the local vulnerable application

set -e

# Configuration
TARGET_URL="${1:-http://localhost:3000}"
REPORT_DIR="./zap-reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SCAN_NAME="baseline_${TIMESTAMP}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔒 OWASP ZAP Baseline Scan${NC}"
echo "======================================"
echo -e "Target URL: ${GREEN}${TARGET_URL}${NC}"
echo -e "Report Directory: ${GREEN}${REPORT_DIR}${NC}"
echo -e "Scan Name: ${GREEN}${SCAN_NAME}${NC}"
echo ""

# Create reports directory
mkdir -p "${REPORT_DIR}"

# Check if target is accessible
echo -e "${YELLOW}🔍 Checking target accessibility...${NC}"
if curl -s --max-time 10 "${TARGET_URL}" > /dev/null; then
    echo -e "${GREEN}✅ Target is accessible${NC}"
else
    echo -e "${RED}❌ Target is not accessible. Please ensure the application is running.${NC}"
    echo "Start the application with: docker-compose up -d vulnerable-app"
    exit 1
fi

# Wait for application to be fully ready
echo -e "${YELLOW}⏳ Waiting for application to be ready...${NC}"
sleep 5

# Run ZAP baseline scan
echo -e "${YELLOW}🚀 Starting ZAP baseline scan...${NC}"
echo "This may take 2-5 minutes depending on the application size."
echo ""

docker run --rm \
    --network host \
    -v "$(pwd)/${REPORT_DIR}:/zap/wrk/:rw" \
    -v "$(pwd)/.zap:/zap/config/:ro" \
    zaproxy/zap-stable:latest \
    zap-baseline.py \
    -t "${TARGET_URL}" \
    -r "${SCAN_NAME}_report.html" \
    -J "${SCAN_NAME}_report.json" \
    -a \
    -d

# Check scan results
SCAN_EXIT_CODE=$?

echo ""
echo "======================================"
if [ $SCAN_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Baseline scan completed successfully!${NC}"
    echo -e "${GREEN}No security issues found or only low-risk issues detected.${NC}"
elif [ $SCAN_EXIT_CODE -eq 1 ]; then
    echo -e "${YELLOW}⚠️  Baseline scan completed with warnings.${NC}"
    echo -e "${YELLOW}Low-risk security issues detected.${NC}"
elif [ $SCAN_EXIT_CODE -eq 2 ]; then
    echo -e "${RED}🚨 Baseline scan found medium-risk security issues!${NC}"
elif [ $SCAN_EXIT_CODE -eq 3 ]; then
    echo -e "${RED}🚨 Baseline scan found high-risk security issues!${NC}"
else
    echo -e "${RED}❌ Scan failed with exit code: ${SCAN_EXIT_CODE}${NC}"
fi

# Display report locations
echo ""
echo -e "${BLUE}📋 Report Files:${NC}"
if [ -f "${REPORT_DIR}/${SCAN_NAME}_report.html" ]; then
    echo -e "  HTML Report: ${GREEN}${REPORT_DIR}/${SCAN_NAME}_report.html${NC}"
fi
if [ -f "${REPORT_DIR}/${SCAN_NAME}_report.json" ]; then
    echo -e "  JSON Report: ${GREEN}${REPORT_DIR}/${SCAN_NAME}_report.json${NC}"
fi
if [ -f "${REPORT_DIR}/${SCAN_NAME}_report.md" ]; then
    echo -e "  Markdown Report: ${GREEN}${REPORT_DIR}/${SCAN_NAME}_report.md${NC}"
fi

# Generate summary
echo ""
echo -e "${BLUE}📊 Quick Summary:${NC}"
if [ -f "${REPORT_DIR}/${SCAN_NAME}_report.json" ]; then
    if command -v jq > /dev/null; then
        HIGH_RISK=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("High"))] | length' "${REPORT_DIR}/${SCAN_NAME}_report.json" 2>/dev/null || echo "0")
        MEDIUM_RISK=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("Medium"))] | length' "${REPORT_DIR}/${SCAN_NAME}_report.json" 2>/dev/null || echo "0")
        LOW_RISK=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("Low"))] | length' "${REPORT_DIR}/${SCAN_NAME}_report.json" 2>/dev/null || echo "0")
        INFO_RISK=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("Informational"))] | length' "${REPORT_DIR}/${SCAN_NAME}_report.json" 2>/dev/null || echo "0")
        
        echo -e "  🔴 High Risk: ${HIGH_RISK}"
        echo -e "  🟡 Medium Risk: ${MEDIUM_RISK}"
        echo -e "  🟢 Low Risk: ${LOW_RISK}"
        echo -e "  ℹ️  Informational: ${INFO_RISK}"
    else
        echo -e "  ${YELLOW}Install 'jq' to see detailed risk breakdown${NC}"
    fi
fi

echo ""
echo -e "${BLUE}💡 Next Steps:${NC}"
echo "  1. Open the HTML report in your browser for detailed findings"
echo "  2. Review the JSON report for programmatic analysis"
echo "  3. Run a full scan for comprehensive testing: ./scripts/zap-full-scan.sh"
echo ""

exit $SCAN_EXIT_CODE