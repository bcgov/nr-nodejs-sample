import { Test, TestingModule } from '@nestjs/testing';
import { createMock, DeepMocked } from '@golevelup/ts-jest';
import { AppController } from './app.controller';
import { AppService } from './app.service';

describe('AppController', () => {
  let appController: AppController;
  let appService: DeepMocked<AppService>;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        AppService,
        {
          provide: AppService,
          useValue: createMock<AppService>(),
        },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
    appService = app.get<AppService>(AppService) as DeepMocked<AppService>;
  });

  describe('root', () => {
    it('should return "Hello World!"', async () => {
      appService.getHello.mockResolvedValue('Hello World!');
      expect(await appController.getHello()).toBe('Hello World!');
    });
  });
});
