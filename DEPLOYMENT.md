# Deployment Guide

This guide explains how to deploy the split frontend and backend applications to Vercel.

## Prerequisites

1. **Vercel Account**: Create a free account at [vercel.com](https://vercel.com)
2. **Vercel CLI**: Install with `npm i -g vercel`
3. **GitHub Repository**: Push your code to a GitHub repository

## Step 1: Create Vercel Projects

### Backend Project
```bash
cd backend
vercel --confirm
# Follow prompts to create new project
# Note the project ID from the output
```

### Frontend Project
```bash
cd ../frontend
vercel --confirm
# Follow prompts to create new project
# Note the project ID from the output
```

## Step 2: Configure GitHub Secrets

In your GitHub repository, go to Settings > Secrets and variables > Actions, and add:

```
VERCEL_TOKEN=your_vercel_token
VERCEL_ORG_ID=your_org_id
VERCEL_BACKEND_PROJECT_ID=backend_project_id
VERCEL_FRONTEND_PROJECT_ID=frontend_project_id
```

### Getting the Values:
- **VERCEL_TOKEN**: Go to Vercel Dashboard > Settings > Tokens > Create Token
- **VERCEL_ORG_ID**: Run `vercel whoami` or check your Vercel dashboard URL
- **Project IDs**: From the `.vercel/project.json` files created in step 1

## Step 3: Update Environment Variables

### Backend Environment
The backend is already configured with CORS to accept requests from Vercel deployments.

### Frontend Environment
1. Deploy the backend first to get the production URL
2. Update `frontend/.env.local`:
```env
NEXT_PUBLIC_BACKEND_URL=https://your-backend-project.vercel.app
```

## Step 4: Deploy

### Manual Deployment
```bash
# Deploy backend
cd backend
vercel --prod

# Deploy frontend (after updating backend URL)
cd ../frontend
vercel --prod
```

### Automatic Deployment
Push to the `main` branch to trigger automatic deployments via GitHub Actions.

## Step 5: Test the Deployment

1. Visit your frontend URL
2. Navigate to `/users` and `/products` pages
3. Verify API calls are working (check browser network tab)
4. Test the vulnerable endpoints for ZAP scanning

## Local Development with Split Architecture

Run both services locally:
```bash
# Terminal 1 - Backend
cd backend
npm run start:dev

# Terminal 2 - Frontend
cd frontend
npm run dev

# Terminal 3 - Docker services (optional)
docker-compose up
```

## ZAP Scanning Configuration

The OWASP ZAP workflows are configured with three separate scan types:

### Frontend Scanning
- **Baseline Scan**: Runs on frontend feature branches and PRs
- **Full Scan**: Runs on main branch pushes for comprehensive frontend security testing
- **Target**: Frontend deployment URL (user interface)

### Backend API Scanning  
- **API Baseline Scan**: Runs on backend feature branches and PRs
- **Target**: Backend API endpoints (`/api/*`)
- **Tests**: SQL injection vulnerabilities, authentication issues, API-specific security concerns
- **Endpoints Tested**: `/api/users`, `/api/products`, `/api/health`

### Scan Triggers
- **Frontend changes**: Triggers frontend scanning workflows
- **Backend changes**: Triggers backend API scanning workflows  
- **Main branch**: Triggers comprehensive full scans
- **Manual trigger**: All workflows support `workflow_dispatch`

## Troubleshooting

### CORS Issues
- Ensure the frontend URL is added to the backend CORS configuration in `backend/vercel.ts:26-32`

### API Connection Issues
- Verify `NEXT_PUBLIC_BACKEND_URL` is correctly set in frontend environment
- Check backend deployment logs in Vercel dashboard

### Build Failures
- Ensure all dependencies are installed: `npm ci` in both directories
- Check for TypeScript errors: `npm run build` locally

### ZAP Scan Failures
- Verify deployment URLs are accessible
- Check if frontend is properly connected to backend
- Review ZAP scan logs in GitHub Actions