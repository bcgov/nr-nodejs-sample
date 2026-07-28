import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('health')
  getHealth(): { status: string; timestamp: string } {
    return {
      status: 'OK',
      timestamp: new Date().toISOString(),
    };
  }

  @Get()
  async getHello(): Promise<string> {
    try {
      const html = await this.appService.getHello();
      return html;
    } catch (error) {
      console.error('Error generating page:', error);
      // Fallback display on error
      return `<!DOCTYPE html>
<html lang="en">
<head><title>Error</title></head>
<body style='font-family: Arial, sans-serif;'>
  <h1>Welcome to ${process.env.PROJECT_NAME || 'Service'}</h1>
  <p style='color: red;'><strong>An unexpected error occurred while generating the page.</strong></p>
  <p>Please check server logs for details. Service is still running though!</p>
</body>
</html>`;
    }
  }
}
