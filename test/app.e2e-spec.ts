import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from './../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  it('/ (GET) returns the status page', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect('Content-Type', /html/)
      .expect((response) => {
        if (!response.text.includes('oscar-example / nodejs-sample')) {
          throw new Error('Status page heading was not rendered');
        }
      });
  });

  it('/tasks (GET) returns the maintenance task list', () => {
    return request(app.getHttpServer())
      .get('/tasks')
      .expect(200)
      .expect('Content-Type', /html/)
      .expect((response) => {
        if (!response.text.includes('maintenance tasks') || !response.text.includes('Verify backup restoration')) {
          throw new Error('Maintenance task list was not rendered');
        }
      });
  });
});
