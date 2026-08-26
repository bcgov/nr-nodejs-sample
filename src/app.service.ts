import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PROJECT_NAME, SERVICE_NAME } from './constants';
import { TaskRecord, TasksService } from './tasks/tasks.service';

@Injectable()
export class AppService {
  constructor(
    private configService: ConfigService,
    private tasksService: TasksService,
  ) {}

  private escapeHtml(value: string): string {
    return value
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  private getDeploymentMetadata(environment: string) {
    const project = process.env.PROJECT_NAME || PROJECT_NAME;
    const service = process.env.SERVICE_NAME || SERVICE_NAME;

    const deploymentVersion =
      process.env.VERSION || process.env.IMAGE_TAG || process.env.APP_VERSION || 'unknown';
    const gitCommit =
      process.env.GITHUB_SHA ||
      process.env.COMMIT_SHA ||
      process.env.GIT_COMMIT ||
      process.env.PACKAGE_BUILD_VERSION ||
      'unknown';
    const buildId =
      process.env.GITHUB_RUN_ID || process.env.BUILD_GUID || process.env.BUILD_ID || 'unknown';

    return {
      project,
      service,
      environment,
      deploymentVersion,
      gitCommit,
      buildId,
    };
  }

  async getHello(): Promise<string> {
    const environment = this.configService.get<string>('environment') || 'local';

    const now = new Date();
    const metadata = this.getDeploymentMetadata(environment);

    const safeProject = this.escapeHtml(metadata.project);
    const safeService = this.escapeHtml(metadata.service);
    const safeEnvironment = this.escapeHtml(metadata.environment);
    const safeDeploymentVersion = this.escapeHtml(metadata.deploymentVersion);
    const safeCommit = this.escapeHtml(metadata.gitCommit);
    const safeBuildId = this.escapeHtml(metadata.buildId);
    const safeNodeVersion = this.escapeHtml(process.version);
    const safeUptime = this.escapeHtml(
      `${Math.floor(process.uptime() / 60)}m ${Math.floor(process.uptime() % 60)}s`,
    );
    const safeNow = this.escapeHtml(now.toLocaleString());

    const shortCommit =
      metadata.gitCommit === 'unknown'
        ? 'unknown'
        : this.escapeHtml(metadata.gitCommit.slice(0, 12));

    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${safeProject} status</title>
  <style>
    :root {
      color-scheme: light;
      --bg-start: #f5f2ea;
      --bg-end: #d9e6f2;
      --card: #ffffff;
      --text: #1e2732;
      --muted: #5f6b78;
      --accent: #0f5f8f;
      --border: #d5dee7;
      --shadow: 0 12px 36px rgba(33, 52, 70, 0.12);
    }

    * { box-sizing: border-box; }

    body {
      margin: 0;
      font-family: "IBM Plex Sans", "Segoe UI", sans-serif;
      color: var(--text);
      background:
        radial-gradient(circle at 90% 10%, rgba(15, 95, 143, 0.18), transparent 45%),
        radial-gradient(circle at 10% 90%, rgba(30, 127, 81, 0.14), transparent 45%),
        linear-gradient(160deg, var(--bg-start), var(--bg-end));
      min-height: 100vh;
      padding: 24px;
    }

    .shell {
      max-width: 1080px;
      margin: 0 auto;
      display: grid;
      gap: 18px;
    }

    .hero {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 18px;
      padding: 22px;
      box-shadow: var(--shadow);
    }

    .title {
      margin: 0;
      font-family: "IBM Plex Serif", Georgia, serif;
      font-weight: 600;
      letter-spacing: 0.2px;
      font-size: clamp(1.6rem, 4vw, 2.2rem);
    }

    .subtitle {
      margin-top: 8px;
      color: var(--muted);
      font-size: 0.98rem;
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
      gap: 14px;
    }

    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 16px;
      box-shadow: var(--shadow);
    }

    .card h2 {
      margin: 0 0 10px;
      font-size: 1.02rem;
      font-weight: 700;
      color: var(--accent);
      letter-spacing: 0.3px;
    }

    dl {
      margin: 0;
      display: grid;
      grid-template-columns: minmax(110px, 1fr) 2fr;
      row-gap: 8px;
      column-gap: 10px;
      font-size: 0.95rem;
    }

    dt {
      color: var(--muted);
      font-weight: 600;
    }

    dd {
      margin: 0;
      word-break: break-word;
      font-family: "IBM Plex Mono", Consolas, monospace;
      font-size: 0.9rem;
    }

  </style>
</head>
<body>
  <main class="shell">
    <section class="hero">
      <h1 class="title">${safeProject} / ${safeService}</h1>
      <p class="subtitle">Live deployment and runtime status</p>
    </section>

    <section class="grid">
      <article class="card">
        <h2>Deployment</h2>
        <dl>
          <dt>Environment</dt><dd>${safeEnvironment}</dd>
          <dt>Version</dt><dd>${safeDeploymentVersion}</dd>
          <dt>Commit</dt><dd>${shortCommit}</dd>
          <dt>Build ID</dt><dd>${safeBuildId}</dd>
        </dl>
      </article>

      <article class="card">
        <h2>Runtime</h2>
        <dl>
          <dt>Node</dt><dd>${safeNodeVersion}</dd>
          <dt>Uptime</dt><dd>${safeUptime}</dd>
          <dt>Now</dt><dd>${safeNow}</dd>
        </dl>
      </article>
    </section>
  </main>
</body>
</html>`;
  }

  getTasksPage(): string {
    const tasks = this.tasksService.getTasks();
    const safeProject = this.escapeHtml(process.env.PROJECT_NAME || PROJECT_NAME);
    const overdueCount = tasks.filter((task) => task.isOverdue).length;
    const rows = tasks
      .map((task) => {
        const status = task.isOverdue ? `Overdue by ${task.daysOverdue} day(s)` : 'On schedule';
        const safeStatus = this.escapeHtml(status);
        return `
          <tr class="${task.isOverdue ? 'overdue' : ''}">
            <td><strong>${this.escapeHtml(task.title)}</strong><br><span>${this.escapeHtml(task.description)}</span></td>
            <td>${this.escapeHtml(task.dueDate || 'unknown')}</td>
            <td>${this.escapeHtml(task.last_completed || 'never')}</td>
            <td><span class="status">${safeStatus}</span></td>
          </tr>`;
      })
      .join('');

    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Team OSCAR Maintenance Tasks</title>
  <style>
    :root { color-scheme: light; --ink: #17212b; --muted: #61707d; --line: #d5dee4; --paper: #fff; --accent: #0b6878; --danger: #a33a32; --danger-bg: #fff0ed; }
    * { box-sizing: border-box; }
    body { margin: 0; padding: 24px; min-height: 100vh; color: var(--ink); background: linear-gradient(145deg, #e8f1ef, #f7f3e9); font-family: "IBM Plex Sans", "Segoe UI", sans-serif; }
    main { max-width: 1180px; margin: 0 auto; }
    header { margin-bottom: 20px; }
    h1 { margin: 0; font-family: "IBM Plex Serif", Georgia, serif; font-size: clamp(1.8rem, 4vw, 2.8rem); }
    header p { color: var(--muted); margin: 8px 0 0; }
    .summary { display: inline-block; margin-top: 16px; padding: 7px 10px; border: 1px solid var(--line); border-radius: 999px; background: var(--paper); color: var(--muted); font-size: .9rem; }
    .table-wrap { overflow-x: auto; background: var(--paper); border: 1px solid var(--line); border-radius: 8px; box-shadow: 0 12px 30px rgba(23, 33, 43, .1); }
    table { width: 100%; border-collapse: collapse; min-width: 720px; }
    th, td { padding: 15px 16px; text-align: left; vertical-align: top; border-bottom: 1px solid var(--line); }
    th { color: var(--muted); background: #f5f8f7; font-size: .78rem; letter-spacing: .08em; text-transform: uppercase; }
    tr:last-child td { border-bottom: 0; }
    td span { color: var(--muted); font-size: .9rem; }
    .overdue { background: var(--danger-bg); }
    .overdue .status { color: var(--danger); font-weight: 700; }
    .status { color: var(--accent); font-weight: 600; white-space: nowrap; }
    @media (max-width: 600px) { body { padding: 16px; } th, td { padding: 12px; } }
  </style>
</head>
<body>
  <main>
    <header>
      <h1>Team OSCAR Maintenance Tasks</h1>
      <p>Recurring operational work and its current due status.</p>
      <span class="summary">${overdueCount} overdue of ${tasks.length} task(s)</span>
    </header>
    <div class="table-wrap">
      <table>
        <thead><tr><th>Task</th><th>Due date</th><th>Last completed</th><th>Status</th></tr></thead>
        <tbody>${rows || '<tr><td colspan="4">No maintenance tasks configured.</td></tr>'}</tbody>
      </table>
    </div>
  </main>
</body>
</html>`;
  }
}


