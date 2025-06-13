/** @type {import('next').NextConfig} */
const nextConfig = {
  env: {
    BACKEND_URL: process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001',
  },
  async rewrites() {
    // Only use rewrites for local development
    if (process.env.NODE_ENV === 'development') {
      return [
        {
          source: '/api/:path*',
          destination: `${process.env.BACKEND_URL || 'http://localhost:3001'}/:path*`,
        },
      ];
    }
    return [];
  },
};

module.exports = nextConfig;