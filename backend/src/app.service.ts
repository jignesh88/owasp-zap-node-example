import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return 'OWASP ZAP Showcase Backend API';
  }
}