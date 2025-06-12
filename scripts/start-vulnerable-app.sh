#!/bin/bash

# Start Vulnerable Application Script
# This script builds and starts the vulnerable Next.js application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Vulnerable Application${NC}"
echo "===================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check if port 3000 is already in use
if lsof -i :3000 > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Port 3000 is already in use.${NC}"
    echo "Checking if it's our application..."
    
    if curl -s http://localhost:3000/api/vulnerable/users > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Vulnerable application is already running!${NC}"
        echo -e "Access it at: ${GREEN}http://localhost:3000${NC}"
        exit 0
    else
        echo -e "${RED}❌ Port 3000 is used by another application.${NC}"
        echo "Please stop the other application or use a different port."
        exit 1
    fi
fi

# Create data directory
mkdir -p ./data

# Choose database type
DB_TYPE="${1:-libsql}"

if [ "$DB_TYPE" = "simple" ]; then
    echo -e "${YELLOW}🔨 Building Docker image with simple database...${NC}"
    docker-compose --profile simple build vulnerable-app-simple
    
    echo -e "${YELLOW}🚀 Starting vulnerable application with simple database...${NC}"
    docker-compose --profile simple up -d vulnerable-app-simple
    
    echo -e "${GREEN}✅ Application with simple database started on port 3001!${NC}"
    TARGET_PORT="3001"
else
    echo -e "${YELLOW}🔨 Building Docker image with LibSQL database...${NC}"
    docker-compose build vulnerable-app
    
    echo -e "${YELLOW}🚀 Starting vulnerable application with LibSQL database...${NC}"
    docker-compose up -d vulnerable-app
    
    echo -e "${GREEN}✅ Application with LibSQL database started on port 3000!${NC}"
    TARGET_PORT="3000"
fi

# Wait for the application to start
echo -e "${YELLOW}⏳ Waiting for application to start...${NC}"
sleep 15

# Check if application is healthy
MAX_ATTEMPTS=30
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if curl -s http://localhost:${TARGET_PORT} > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Application started successfully!${NC}"
        break
    else
        echo -n "."
        sleep 2
        ATTEMPT=$((ATTEMPT + 1))
    fi
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    echo -e "${RED}❌ Application failed to start within expected time.${NC}"
    echo "Checking logs..."
    if [ "$DB_TYPE" = "simple" ]; then
        docker-compose --profile simple logs vulnerable-app-simple
    else
        docker-compose logs vulnerable-app
    fi
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Vulnerable Application Ready!${NC}"
echo "================================="
echo -e "Application URL: ${GREEN}http://localhost:${TARGET_PORT}${NC}"
echo ""
echo -e "${BLUE}📚 Available Vulnerable Endpoints:${NC}"
echo "  • GET  /api/vulnerable/users?search=<query>"
echo "  • GET  /api/vulnerable/users?id=<id>"
echo "  • POST /api/vulnerable/login"
echo "  • GET  /api/vulnerable/products?category=<cat>"
echo "  • GET  /api/vulnerable/orders?userId=<id>"
echo "  • POST /api/vulnerable/admin"
echo ""
echo -e "${BLUE}🔧 Example SQL Injection Payloads:${NC}"
echo "  /api/vulnerable/users?id=1' OR '1'='1"
echo "  /api/vulnerable/users?search=admin' UNION SELECT 1,2,3,4,5--"
echo "  /api/vulnerable/products?category=electronics' OR '1'='1"
echo ""
echo -e "${BLUE}🔒 Run Security Scans:${NC}"
echo "  Setup ZAP:     ./scripts/setup-zap-docker.sh"
echo "  Baseline Scan: ./scripts/zap-baseline-scan.sh http://localhost:${TARGET_PORT}"
echo "  Full Scan:     ./scripts/zap-full-scan.sh http://localhost:${TARGET_PORT}"
echo ""
echo -e "${BLUE}🔧 Database Info:${NC}"
if [ "$DB_TYPE" = "simple" ]; then
    echo "  Database: Simple in-memory database"
    echo "  Features: Zero dependencies, auto SQL injection detection"
else
    echo "  Database: LibSQL database (Turso-compatible)"
    echo "  Features: Modern SQLite, edge-optimized, no native dependencies"
fi
echo ""
echo -e "${BLUE}🛑 Stop Application:${NC}"
if [ "$DB_TYPE" = "simple" ]; then
    echo "  docker-compose --profile simple down"
else
    echo "  docker-compose down"
fi
echo ""
echo -e "${BLUE}💡 Alternative Database:${NC}"
if [ "$DB_TYPE" = "simple" ]; then
    echo "  For LibSQL database: ./scripts/start-vulnerable-app.sh"
else
    echo "  For simple database: ./scripts/start-vulnerable-app.sh simple"
fi
echo ""