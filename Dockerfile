FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install system dependencies for building native modules
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    sqlite \
    sqlite-dev \
    pkgconfig

# Copy package files first for better caching
COPY frontend/package*.json ./frontend/
COPY package*.json ./

# Install dependencies and rebuild native modules for Alpine
WORKDIR /app/frontend
RUN npm install --only=production && \
    npm rebuild better-sqlite3

# Copy application code
COPY frontend/ ./

# Build the application
RUN npm run build

# Expose port
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Create directory for SQLite database
RUN mkdir -p /app/data

# Start the application
CMD ["npm", "start"]