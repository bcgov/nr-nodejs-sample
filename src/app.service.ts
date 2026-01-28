import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { PROJECT_NAME, SERVICE_NAME, BROKER_URL } from './constants';

@Injectable()
export class AppService {
  constructor(private configService: ConfigService) {}

  async getHello(): Promise<string> {
    const apitoken = this.configService.get<string>('apitoken');
    const environment = this.configService.get<string>('environment');
    let packageVersion = 'unknown';
    let transactionStart = 'unknown';
    let transactionEnd = 'unknown';
    let eventUrl = 'unknown';
    try {
      const where = {
        'actions.action': 'package-installation',
        'actions.service.project': PROJECT_NAME,
        'actions.service.name': SERVICE_NAME,
        'actions.service.environment': environment,
      };
      const params = new URLSearchParams({
        where: JSON.stringify(where),
        offset: '0',
        limit: '1',
      });

      const requestUrl = `${BROKER_URL}/v1/intention/search?${params.toString()}`;
      const response = await axios.post(
        requestUrl,
        '', // POST body is empty string as in your curl
        {
          headers: {
            accept: 'application/json',
            Authorization: `Bearer ${apitoken}`,
          },
        },
      );
      const data = response.data?.data?.[0];
      if (data) {
        // Find the package-installation action
        const pkgInstallAction = data.actions?.find(
          (a: any) => a.action === 'package-installation',
        );
        if (pkgInstallAction) {
          packageVersion = pkgInstallAction.package?.version ?? 'unknown';
        }
        // Transaction times
        if (data.transaction) {
          // Convert to local time string
          transactionStart = new Date(data.transaction.start).toLocaleString();
          transactionEnd = new Date(data.transaction.end).toLocaleString();
        }
        // Event URL
        eventUrl = data.event?.url ?? 'unknown';
      }
    } catch (error) {
      // handle error or log
    }

    return `
      <h1>Welcome to ${PROJECT_NAME}</h1>
      <p>Service: ${SERVICE_NAME}</p>
      <p>Environment: ${environment}</p>
      <p>Package Version: ${packageVersion}</p>
      <p>Transaction Start: ${transactionStart}</p>
      <p>Transaction End: ${transactionEnd}</p>
      <p>Event URL: ${eventUrl}</p>
    `;
  }
}
