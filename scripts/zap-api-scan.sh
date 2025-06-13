#!/bin/bash

# OWASP ZAP API Baseline Scan Script for Backend
# Usage: ./scripts/zap-api-scan.sh [TARGET_URL] [REPORT_DIR]

set -e

# Configuration
TARGET_URL="${1:-http://localhost:3001/api}"
REPORT_DIR="${2:-zap-reports/api}"
MAX_DURATION="${3:-5}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔒 Starting OWASP ZAP API Baseline Scan${NC}"
echo -e "${BLUE}Target API: ${TARGET_URL}${NC}"
echo -e "${BLUE}Report Directory: ${REPORT_DIR}${NC}"
echo -e "${BLUE}Max Duration: ${MAX_DURATION} minutes${NC}"
echo "=============================================="

# Create report directory
mkdir -p "${REPORT_DIR}"

# Test API endpoints before scanning
echo -e "${YELLOW}🔍 Testing API endpoints...${NC}"

test_endpoint() {
    local endpoint=$1
    local description=$2
    echo -n "Testing ${endpoint}... "
    
    if curl -s -f "${TARGET_URL}${endpoint}" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Available${NC}"
        return 0
    else
        echo -e "${RED}❌ Not Available${NC}"
        return 1
    fi
}

# Test basic endpoints
test_endpoint "/health" "Health check"
test_endpoint "/users" "Users endpoint"
test_endpoint "/products" "Products endpoint"

# Test vulnerable endpoints (SQL injection attempts)
echo -e "${YELLOW}🚨 Testing for SQL injection vulnerabilities...${NC}"

test_sql_injection() {
    local endpoint=$1
    local payload=$2
    local description=$3
    echo -n "Testing ${description}... "
    
    # URL encode the SQL injection payload
    local encoded_payload=$(echo "$payload" | sed 's/ /%20/g' | sed "s/'/%27/g" | sed 's/=/%3D/g')
    local full_url="${TARGET_URL}${endpoint}${encoded_payload}"
    
    if curl -s -f "$full_url" > /dev/null 2>&1; then
        echo -e "${RED}⚠️ Potentially Vulnerable${NC}"
        return 0
    else
        echo -e "${GREEN}✅ Protected${NC}"
        return 1
    fi
}

test_sql_injection "/users?search=" "admin' OR '1'='1" "SQL injection in users search"
test_sql_injection "/products?category=" "electronics' OR '1'='1" "SQL injection in products category"
test_sql_injection "/products?minPrice=" "0' OR '1'='1" "SQL injection in products price filter"

echo "=============================================="

# Create ZAP configuration for API scanning
echo -e "${YELLOW}📝 Creating ZAP API scan configuration...${NC}"

mkdir -p .zap/api-config

cat > .zap/api-config/api-scan-${TIMESTAMP}.yaml << EOF
env:
  contexts:
    - name: "Backend API"
      urls:
        - "${TARGET_URL}/"
      includePaths:
        - "${TARGET_URL}/.*"
      excludePaths: []
      authentication:
        method: "none"
  parameters:
    globalExcludeUrl: []
    activeScanMaxDuration: ${MAX_DURATION}
    passiveScanMaxDuration: 2
    defaultPolicy: "API-minimal-example"
jobs:
  - type: passiveScan-config
    parameters:
      maxAlertsPerRule: 10
  - type: activeScan-config
    parameters:
      policy: "API-minimal-example"
      contextName: "Backend API"
      user: ""
EOF

echo -e "${GREEN}✅ Configuration created${NC}"

# Run ZAP API scan
echo -e "${YELLOW}🔒 Running OWASP ZAP API scan...${NC}"

# Check if ZAP Docker image exists
if ! docker image inspect zaproxy/zap-stable:latest > /dev/null 2>&1; then
    echo -e "${YELLOW}📥 Pulling ZAP Docker image...${NC}"
    docker pull zaproxy/zap-stable:latest
fi

# Run the ZAP API scan
docker run --rm \
    --network host \
    -v "$(pwd)/${REPORT_DIR}:/zap/wrk/:rw" \
    -v "$(pwd)/.zap:/zap/config/:ro" \
    zaproxy/zap-stable:latest \
    zap-api-scan.py \
    -t "${TARGET_URL}/openapi.json" \
    -f openapi \
    -c "/zap/config/api-config/api-scan-${TIMESTAMP}.yaml" \
    -r "api-baseline-report-${TIMESTAMP}.html" \
    -J "api-baseline-report-${TIMESTAMP}.json" \
    -m ${MAX_DURATION} \
    -d

echo "=============================================="

# Generate summary report
echo -e "${YELLOW}📊 Generating scan summary...${NC}"

REPORT_FILE="${REPORT_DIR}/api-baseline-report-${TIMESTAMP}.json"

if [ -f "$REPORT_FILE" ]; then
    # Extract key metrics from JSON report
    HIGH_RISK=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("High"))] | length' "$REPORT_FILE" 2>/dev/null || echo "0")
    MEDIUM_RISK=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("Medium"))] | length' "$REPORT_FILE" 2>/dev/null || echo "0")
    LOW_RISK=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("Low"))] | length' "$REPORT_FILE" 2>/dev/null || echo "0")
    INFO_RISK=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("Informational"))] | length' "$REPORT_FILE" 2>/dev/null || echo "0")
    TOTAL_ISSUES=$((HIGH_RISK + MEDIUM_RISK + LOW_RISK + INFO_RISK))
    
    # Create summary report
    cat > "${REPORT_DIR}/scan-summary-${TIMESTAMP}.txt" << EOF
OWASP ZAP API Baseline Scan Summary
==================================
Target API: ${TARGET_URL}
Scan Date: $(date)
Scan Duration: ${MAX_DURATION} minutes

Security Issues Found:
- High Risk: ${HIGH_RISK}
- Medium Risk: ${MEDIUM_RISK}  
- Low Risk: ${LOW_RISK}
- Informational: ${INFO_RISK}
- Total: ${TOTAL_ISSUES}

Reports Generated:
- HTML Report: api-baseline-report-${TIMESTAMP}.html
- JSON Report: api-baseline-report-${TIMESTAMP}.json
- Summary: scan-summary-${TIMESTAMP}.txt
EOF

    echo -e "${GREEN}✅ Scan completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}📊 Scan Results Summary:${NC}"
    echo -e "${RED}🔴 High Risk Issues: ${HIGH_RISK}${NC}"
    echo -e "${YELLOW}🟡 Medium Risk Issues: ${MEDIUM_RISK}${NC}"
    echo -e "${GREEN}🟢 Low Risk Issues: ${LOW_RISK}${NC}"
    echo -e "${BLUE}ℹ️ Informational: ${INFO_RISK}${NC}"
    echo -e "${BLUE}📁 Reports saved to: ${REPORT_DIR}${NC}"
    
    if [ $HIGH_RISK -gt 0 ] || [ $MEDIUM_RISK -gt 0 ]; then
        echo -e "${RED}⚠️ Security issues found! Review the reports for details.${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ No critical security issues found.${NC}"
    fi
else
    echo -e "${RED}❌ Scan report not generated. Check ZAP logs for errors.${NC}"
    exit 1
fi