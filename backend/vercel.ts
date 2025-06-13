import { NestFactory } from '@nestjs/core';
import { ExpressAdapter } from '@nestjs/platform-express';
import { AppModule } from './api/app.module';
import { configure as serverlessExpress } from '@vendia/serverless-express';
import express from 'express';

let cachedServer: any;

async function bootstrapServer() {
  if (!cachedServer) {
    try {
      const expressApp = express();
      
      // Create NestJS application with Express adapter
      const nestApp = await NestFactory.create(
        AppModule,
        new ExpressAdapter(expressApp),
        {
          logger: ['error', 'warn', 'log'],
        }
      );
      
      // Enable CORS for separated frontend deployment
      nestApp.enableCors({
        origin: [
          'https://owasp-zap-frontend.vercel.app',
          'http://localhost:3000', // For local development
          /\.vercel\.app$/, // Allow any Vercel preview deployments
        ],
        credentials: true,
        methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        allowedHeaders: ['Content-Type', 'Authorization'],
      });
      
      // Set global prefix to match routing
      nestApp.setGlobalPrefix('api');
      
      // Initialize the NestJS application
      await nestApp.init();
      
      // Configure serverless express wrapper
      cachedServer = serverlessExpress({
        app: expressApp,
        logSettings: {
          level: 'info'
        }
      });
      
      console.log('NestJS application initialized for Vercel');
    } catch (error) {
      console.error('Failed to initialize NestJS application:', error);
      throw error;
    }
  }
  
  return cachedServer;
}

// Vercel serverless function handler
export default async function handler(req: any, res: any) {
  try {
    const server = await bootstrapServer();
    return server(req, res);
  } catch (error) {
    console.error('Handler error:', error);
    return res.status(500).json({ 
      error: 'Internal Server Error',
      message: 'Failed to initialize application'
    });
  }
}