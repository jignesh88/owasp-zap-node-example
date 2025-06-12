# OWASP ZAP CI/CD Integration Showcase

This project demonstrates how to integrate OWASP ZAP security testing into a modern CI/CD pipeline using GitHub Actions and Vercel deployment.

## 🏗️ Architecture

### Frontend
- **Framework**: Next.js 14 with TypeScript
- **Styling**: Tailwind CSS
- **Deployment**: Vercel

### Backend
- **Framework**: NestJS with TypeScript
- **API**: RESTful endpoints
- **Deployment**: Vercel Functions

### Security Testing
- **Tool**: OWASP ZAP (Zed Attack Proxy)
- **Integration**: GitHub Actions workflows
- **Reporting**: Automated artifacts and PR comments

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- npm or yarn
- Git

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd owasp-zap-node-example
   ```

2. **Install dependencies**
   ```bash
   npm run install:all
   ```

3. **Start development servers**
   ```bash
   npm run dev
   ```
   - Frontend: http://localhost:3000
   - Backend: http://localhost:3001

### Build for Production

```bash
npm run build
```

## 🔒 Security Testing

### Scan Types

#### 1. Baseline Scan (Feature/Task Branches)
- **Trigger**: Push to feature/*, task/*, bugfix/* branches, or PR to main/master
- **Scope**: Passive security tests only
- **Duration**: ~2-5 minutes
- **Purpose**: Quick security checks without false positives

#### 2. Full Scan (Main/Master & Release Branches)
- **Trigger**: Push to main/master, releases, or weekly schedule
- **Scope**: Complete active and passive security testing
- **Duration**: ~10-30 minutes
- **Purpose**: Comprehensive security assessment

### GitHub Actions Workflows

#### Baseline Scan Workflow (`.github/workflows/zap-baseline-scan.yml`)
- Deploys to Vercel preview environment
- Runs OWASP ZAP baseline scan
- Comments results on PRs
- Uploads scan artifacts

#### Full Scan Workflow (`.github/workflows/zap-full-scan.yml`)
- Deploys to Vercel production environment
- Runs comprehensive OWASP ZAP scan
- Creates GitHub issues for high/medium risks
- Generates security metrics
- Uploads detailed reports

### Security Configuration

#### ZAP Rules
- **Baseline Rules** (`.zap/rules/baseline-rules.tsv`): Conservative ruleset for CI
- **Full Scan Rules** (`.zap/rules/full-scan-rules.tsv`): Comprehensive security tests

#### ZAP Configuration (`.zap/config`)
- Spider and scan settings
- Authentication configuration
- Custom headers and session management

## 📊 Features Tested

### API Endpoints
- **Users API** (`/api/users`): CRUD operations, search functionality
- **Products API** (`/api/products`): Product catalog, filtering
- **Health Check** (`/api/health`): Service status monitoring

### Security Test Coverage
- ✅ SQL Injection
- ✅ Cross-Site Scripting (XSS)
- ✅ Cross-Site Request Forgery (CSRF)
- ✅ Path Traversal
- ✅ Command Injection
- ✅ Information Disclosure
- ✅ Security Headers Analysis
- ✅ Authentication Issues
- ✅ Session Management
- ✅ Input Validation

## 🧪 Local Vulnerability Testing

### Vulnerable Application

This project includes a **deliberately vulnerable** Next.js application for testing OWASP ZAP capabilities:

#### 🚨 Critical SQL Injection Vulnerabilities
- **Unparameterized queries** in all API endpoints
- **Direct string concatenation** in WHERE clauses  
- **No input validation** or sanitization
- **Error messages expose** database structure
- **Admin endpoint** allows arbitrary SQL execution

#### 📍 Vulnerable Endpoints
- `GET /api/vulnerable/users?id=<id>` - Basic SQL injection
- `GET /api/vulnerable/users?search=<query>` - UNION-based injection
- `POST /api/vulnerable/login` - Authentication bypass
- `GET /api/vulnerable/products?orderBy=<column>` - ORDER BY injection
- `POST /api/vulnerable/admin` - Direct SQL execution
- `GET /api/vulnerable/orders?userId=<id>` - Blind SQL injection

### 🚀 Quick Start (Local Testing)

#### 1. Start the Vulnerable Application
```bash
# Start with Docker
./scripts/start-vulnerable-app.sh

# Or manually
docker-compose up -d vulnerable-app
```

#### 2. Test SQL Injection Vulnerabilities
```bash
# Run manual SQL injection tests
./scripts/test-sql-injection.sh

# Test individual endpoints
curl "http://localhost:3000/api/vulnerable/users?id=1' OR '1'='1"
curl "http://localhost:3000/api/vulnerable/users?search=admin' UNION SELECT 1,2,3,4,5--"
```

#### 3. Run OWASP ZAP Scans
```bash
# Quick baseline scan (2-5 minutes)
./scripts/zap-baseline-scan.sh

# Comprehensive full scan (15-45 minutes)
./scripts/zap-full-scan.sh

# Custom target URL
./scripts/zap-full-scan.sh http://localhost:3000 60  # 60 minute max
```

#### 4. View Results
```bash
# View scan reports
open zap-reports/full_*_report.html
cat zap-reports/baseline_*_report.md
```

### 🐳 Docker Setup

#### Using Docker Compose (Recommended)
```bash
# Start vulnerable app
docker-compose up -d vulnerable-app

# Start app with ZAP GUI (optional)
docker-compose up -d zap

# Access ZAP Web UI at http://localhost:8080
```

#### Manual Docker Commands
```bash
# Build the application
docker build -t vulnerable-app .

# Run the application
docker run -p 3000:3000 -v $(pwd)/data:/app/data vulnerable-app

# Run ZAP baseline scan
docker run --rm --network host \
  -v $(pwd)/zap-reports:/zap/wrk/ \
  zaproxy/zap-stable:latest \
  zap-baseline.py -t http://localhost:3000
```

## 🛠️ Setup Instructions

### GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

```
VERCEL_TOKEN=<your-vercel-token>
VERCEL_ORG_ID=<your-vercel-org-id>
VERCEL_PROJECT_ID=<your-vercel-project-id>
```

### Vercel Setup

1. **Install Vercel CLI**
   ```bash
   npm i -g vercel
   ```

2. **Link your project**
   ```bash
   vercel link
   ```

3. **Get organization and project IDs**
   ```bash
   vercel project ls
   ```

### Environment Variables

Create `.env.local` files for local development:

**Frontend** (`.env.local`):
```
BACKEND_URL=http://localhost:3001
```

**Backend** (`.env`):
```
PORT=3001
NODE_ENV=development
```

## 📈 Security Metrics

The workflows generate comprehensive security metrics including:

- **Risk Level Breakdown**: High, Medium, Low, Informational
- **Vulnerability Categories**: Injection, XSS, CSRF, etc.
- **Trend Analysis**: Historical scan comparison
- **Compliance Reports**: Security standard adherence

### Report Formats

- **HTML Report**: Visual dashboard with detailed findings
- **JSON Report**: Machine-readable format for integration
- **Markdown Report**: Human-readable summary for PRs
- **Metrics JSON**: Structured data for analytics

## 🔧 Customization

### Adding New Security Rules

1. Edit `.zap/rules/baseline-rules.tsv` or `.zap/rules/full-scan-rules.tsv`
2. Update rule thresholds: `OFF`, `LOW`, `MEDIUM`, `HIGH`
3. Add ignore patterns for false positives

### Workflow Customization

- **Scan Frequency**: Modify cron schedule in full-scan workflow
- **Deployment Targets**: Update Vercel configuration
- **Notification Settings**: Customize GitHub issue creation logic
- **Report Processing**: Add custom metrics extraction

### Adding Authentication

1. Update `.zap/config` with login URLs and credentials
2. Modify workflows to include authentication setup
3. Configure session management in ZAP rules

## 📜 Scripts Reference

### Application Management
- `./scripts/start-vulnerable-app.sh` - Build and start the vulnerable application
- `./scripts/test-sql-injection.sh` - Manual SQL injection vulnerability tests

### Security Scanning
- `./scripts/zap-baseline-scan.sh [URL]` - Quick passive security scan
- `./scripts/zap-full-scan.sh [URL] [MAX_MINUTES]` - Comprehensive active scan

### Docker Commands
- `docker-compose up -d vulnerable-app` - Start vulnerable application
- `docker-compose up -d zap` - Start ZAP with GUI interface
- `docker-compose down` - Stop all services

## ⚠️ Security Disclaimer

**WARNING**: This application contains **intentional security vulnerabilities** for educational and testing purposes only.

- **Never deploy this to production**
- **Only test against systems you own**
- **Do not use on public networks**
- **Keep the application isolated**

The vulnerable endpoints demonstrate common security flaws:
- SQL Injection (8+ different vectors)
- Authentication bypass
- Information disclosure
- Insufficient input validation

## 📚 Documentation

- [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
- [GitHub Actions ZAP Integration](https://github.com/zaproxy/action-baseline)
- [Vercel Deployment Guide](https://vercel.com/docs)
- [NestJS Security Best Practices](https://docs.nestjs.com/security/authentication)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run security scans locally
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

For questions or issues:
- Open a GitHub issue
- Check the [troubleshooting guide](docs/troubleshooting.md)
- Review workflow logs for scan failures

---

**🔒 Security First**: This project demonstrates security-first development practices with automated vulnerability scanning integrated directly into the development workflow.