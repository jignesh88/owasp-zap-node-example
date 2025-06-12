#!/bin/bash

# OWASP ZAP Full Scan Script
# This script runs a comprehensive security scan against the local vulnerable application

set -e

# Configuration
TARGET_URL="${1:-http://localhost:3000}"
REPORT_DIR="./zap-reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SCAN_NAME="full_${TIMESTAMP}"
MAX_DURATION="${2:-30}"  # Maximum scan duration in minutes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🔒 OWASP ZAP Full Security Scan${NC}"
echo "=========================================="
echo -e "Target URL: ${GREEN}${TARGET_URL}${NC}"
echo -e "Report Directory: ${GREEN}${REPORT_DIR}${NC}"
echo -e "Scan Name: ${GREEN}${SCAN_NAME}${NC}"
echo -e "Max Duration: ${GREEN}${MAX_DURATION} minutes${NC}"
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

# Check for vulnerable endpoints
echo -e "${YELLOW}🔍 Checking for vulnerable endpoints...${NC}"
VULNERABLE_ENDPOINTS=(
    "/api/vulnerable/users"
    "/api/vulnerable/login"
    "/api/vulnerable/products"
    "/api/vulnerable/orders"
    "/api/vulnerable/admin"
)

for endpoint in "${VULNERABLE_ENDPOINTS[@]}"; do
    if curl -s --max-time 5 "${TARGET_URL}${endpoint}" > /dev/null; then
        echo -e "  ${GREEN}✓${NC} ${endpoint}"
    else
        echo -e "  ${YELLOW}⚠${NC} ${endpoint} (may not be accessible)"
    fi
done

# Wait for application to be fully ready
echo -e "${YELLOW}⏳ Waiting for application to be ready...${NC}"
sleep 10

# Create ZAP context file for authentication
echo -e "${YELLOW}📝 Creating ZAP context configuration...${NC}"
cat > "${REPORT_DIR}/context.context" << EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<configuration>
    <context>
        <name>VulnerableApp</name>
        <desc>Vulnerable Application Context</desc>
        <inscope>true</inscope>
        <incregexes>http://localhost:3000/.*</incregexes>
        <excregexes></excregexes>
        <tech>
            <include>Db</include>
            <include>Db.SQLite</include>
            <include>Language</include>
            <include>Language.JavaScript</include>
            <include>OS</include>
            <include>OS.Linux</include>
            <include>SCM</include>
            <include>WS</include>
        </tech>
        <urlparser>
            <class>org.zaproxy.zap.model.StandardParameterParser</class>
            <config></config>
        </urlparser>
        <postparser>
            <class>org.zaproxy.zap.model.StandardParameterParser</class>
            <config></config>
        </postparser>
        <authentication>
            <type>0</type>
        </authentication>
        <users>
        </users>
        <forceduser>-1</forceduser>
        <session>
            <type>0</type>
        </session>
    </context>
</configuration>
EOF

# Run ZAP full scan
echo -e "${PURPLE}🚀 Starting ZAP full security scan...${NC}"
echo "This comprehensive scan may take 15-45 minutes depending on the application complexity."
echo "The scan includes:"
echo "  • Spider crawling to discover all endpoints"
echo "  • Active security testing (SQL injection, XSS, etc.)"
echo "  • Passive security analysis"
echo "  • Authentication bypass attempts"
echo ""

START_TIME=$(date +%s)

# Run the full scan with custom parameters
docker run --rm \
    --network host \
    -v "$(pwd)/${REPORT_DIR}:/zap/wrk/:rw" \
    -v "$(pwd)/.zap:/zap/config/:ro" \
    zaproxy/zap-stable:latest \
    zap-full-scan.py \
    -t "${TARGET_URL}" \
    -g full-scan-rules.conf \
    -r "${SCAN_NAME}_report.html" \
    -J "${SCAN_NAME}_report.json" \
    -m "${SCAN_NAME}_report.md" \
    -x "${SCAN_NAME}_report.xml" \
    -a \
    -d \
    -T ${MAX_DURATION} \
    -z "-configfile /zap/config/config" \
    --hook=/zap/wrk/context.context

# Check scan results
SCAN_EXIT_CODE=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "=========================================="
echo -e "${BLUE}⏱️  Scan Duration: $((DURATION / 60)) minutes $((DURATION % 60)) seconds${NC}"

if [ $SCAN_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Full scan completed successfully!${NC}"
    echo -e "${GREEN}No high-risk security issues found.${NC}"
elif [ $SCAN_EXIT_CODE -eq 1 ]; then
    echo -e "${YELLOW}⚠️  Full scan completed with warnings.${NC}"
    echo -e "${YELLOW}Low-risk security issues detected.${NC}"
elif [ $SCAN_EXIT_CODE -eq 2 ]; then
    echo -e "${RED}🚨 Full scan found medium-risk security issues!${NC}"
elif [ $SCAN_EXIT_CODE -eq 3 ]; then
    echo -e "${RED}🚨 Full scan found high-risk security issues!${NC}"
    echo -e "${RED}🔥 Critical vulnerabilities detected - immediate action required!${NC}"
else
    echo -e "${RED}❌ Scan failed with exit code: ${SCAN_EXIT_CODE}${NC}"
fi

# Display report locations
echo ""
echo -e "${BLUE}📋 Report Files:${NC}"
for report_file in "${REPORT_DIR}/${SCAN_NAME}_report."*; do
    if [ -f "$report_file" ]; then
        echo -e "  $(basename "$report_file"): ${GREEN}${report_file}${NC}"
    fi
done

# Generate detailed summary
echo ""
echo -e "${BLUE}📊 Detailed Security Analysis:${NC}"
if [ -f "${REPORT_DIR}/${SCAN_NAME}_report.json" ]; then
    if command -v jq > /dev/null; then
        # Extract vulnerability counts
        HIGH_RISK=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("High"))] | length' "${REPORT_DIR}/${SCAN_NAME}_report.json" 2>/dev/null || echo "0")
        MEDIUM_RISK=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("Medium"))] | length' "${REPORT_DIR}/${SCAN_NAME}_report.json" 2>/dev/null || echo "0")
        LOW_RISK=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("Low"))] | length' "${REPORT_DIR}/${SCAN_NAME}_report.json" 2>/dev/null || echo "0")
        INFO_RISK=$(jq '[.site[].alerts[] | select(.riskdesc | startswith("Informational"))] | length' "${REPORT_DIR}/${SCAN_NAME}_report.json" 2>/dev/null || echo "0")
        
        echo "╭─────────────────────────────────────╮"
        echo "│             Risk Summary            │"
        echo "├─────────────────────────────────────┤"
        echo -e "│ 🔴 High Risk:        ${HIGH_RISK} issues     │"
        echo -e "│ 🟡 Medium Risk:      ${MEDIUM_RISK} issues     │"
        echo -e "│ 🟢 Low Risk:         ${LOW_RISK} issues     │"
        echo -e "│ ℹ️  Informational:    ${INFO_RISK} issues     │"
        echo "╰─────────────────────────────────────╯"
        
        # Extract top vulnerabilities
        echo ""
        echo -e "${BLUE}🎯 Top Vulnerabilities Found:${NC}"
        jq -r '.site[].alerts[] | select(.riskdesc | startswith("High") or startswith("Medium")) | "  • \(.name) (\(.riskdesc))"' "${REPORT_DIR}/${SCAN_NAME}_report.json" 2>/dev/null | head -10 || echo "  No high/medium risk vulnerabilities found"
        
        # Create security metrics
        cat > "${REPORT_DIR}/${SCAN_NAME}_metrics.json" << EOF
{
  "scan_type": "full",
  "target_url": "${TARGET_URL}",
  "scan_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "duration_seconds": ${DURATION},
  "high_risk_issues": ${HIGH_RISK},
  "medium_risk_issues": ${MEDIUM_RISK},
  "low_risk_issues": ${LOW_RISK},
  "info_risk_issues": ${INFO_RISK},
  "total_issues": $((HIGH_RISK + MEDIUM_RISK + LOW_RISK + INFO_RISK)),
  "exit_code": ${SCAN_EXIT_CODE}
}
EOF
        
    else
        echo -e "  ${YELLOW}Install 'jq' to see detailed risk breakdown${NC}"
    fi
else
    echo -e "  ${YELLOW}JSON report not found - unable to generate summary${NC}"
fi

# SQL Injection specific analysis
echo ""
echo -e "${BLUE}💉 SQL Injection Analysis:${NC}"
if [ -f "${REPORT_DIR}/${SCAN_NAME}_report.json" ] && command -v jq > /dev/null; then
    SQL_ISSUES=$(jq '[.site[].alerts[] | select(.name | contains("SQL"))] | length' "${REPORT_DIR}/${SCAN_NAME}_report.json" 2>/dev/null || echo "0")
    if [ "$SQL_ISSUES" -gt 0 ]; then
        echo -e "  ${RED}🚨 Found ${SQL_ISSUES} SQL injection vulnerabilities!${NC}"
        jq -r '.site[].alerts[] | select(.name | contains("SQL")) | "  • \(.name) in \(.instances[0].uri)"' "${REPORT_DIR}/${SCAN_NAME}_report.json" 2>/dev/null | head -5
    else
        echo -e "  ${GREEN}✅ No SQL injection vulnerabilities detected${NC}"
    fi
fi

echo ""
echo -e "${BLUE}💡 Recommendations:${NC}"
if [ $SCAN_EXIT_CODE -ge 2 ]; then
    echo "  1. 🔥 Address high/medium risk vulnerabilities immediately"
    echo "  2. 📖 Review the HTML report for detailed remediation steps"
    echo "  3. 🔒 Implement input validation and parameterized queries"
    echo "  4. 🛡️  Add security headers and CSRF protection"
    echo "  5. 🔄 Re-run scan after fixes to verify remediation"
else
    echo "  1. 📖 Review the HTML report for any low-risk findings"
    echo "  2. 🔄 Run regular security scans in your CI/CD pipeline"
    echo "  3. 📚 Consider implementing additional security controls"
fi

echo ""
echo -e "${BLUE}📖 How to View Reports:${NC}"
echo "  HTML Report: open ${REPORT_DIR}/${SCAN_NAME}_report.html"
echo "  JSON Report: cat ${REPORT_DIR}/${SCAN_NAME}_report.json | jq"
echo "  Markdown: cat ${REPORT_DIR}/${SCAN_NAME}_report.md"
echo ""

# Cleanup
rm -f "${REPORT_DIR}/context.context"

exit $SCAN_EXIT_CODE