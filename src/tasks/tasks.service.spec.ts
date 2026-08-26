import { TasksService } from './tasks.service';

describe('TasksService', () => {
  let service: TasksService;
  const originalReadFileSync = jest.requireActual('fs').readFileSync;

  beforeEach(() => {
    service = new TasksService();
    jest.spyOn(require('fs'), 'readFileSync').mockImplementation((filePath: string) => {
      if (String(filePath).includes('ops/tasks.yaml')) {
        return `
- id: task-never-completed
  title: Never completed
  description: Example of an overdue task
  cadence_days: 14
  last_completed: '2026-08-01'

- id: task-completed-today
  title: Completed today
  description: Example of a fresh task
  cadence_days: 30
  last_completed: '2026-08-25'

- id: task-upcoming
  title: Upcoming
  description: Example of a future task
  cadence_days: 7
  last_completed: '2026-08-25'
`;
      }
      return originalReadFileSync(filePath, 'utf8');
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('marks overdue tasks ahead of upcoming tasks', () => {
    const tasks = service.getTasks();

    expect(tasks[0].id).toBe('task-never-completed');
    expect(tasks[0].isOverdue).toBe(true);
    expect(tasks[0].daysOverdue).toBeGreaterThan(0);

    expect(tasks.some((task) => task.id === 'task-completed-today')).toBe(true);
    expect(tasks.some((task) => task.id === 'task-upcoming')).toBe(true);
  });

  it('treats today as not overdue', () => {
    const tasks = service.getTasks();
    const todayTask = tasks.find((task) => task.id === 'task-completed-today');

    expect(todayTask?.isOverdue).toBe(false);
    expect(todayTask?.daysOverdue).toBe(0);
  });
});
