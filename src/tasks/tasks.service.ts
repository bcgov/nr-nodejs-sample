import { Injectable } from '@nestjs/common';
import { readFileSync } from 'fs';
import { join } from 'path';
import { parse } from 'yaml';

export interface TaskRecord {
  id: string;
  title: string;
  description: string;
  cadence_days: number;
  last_completed: string;
  last_checked?: string;
  dueDate?: string;
  isOverdue?: boolean;
  daysOverdue?: number;
}

@Injectable()
export class TasksService {
  private readonly tasksPath = join(process.cwd(), 'ops', 'tasks.yaml');

  private parseIsoDate(value: string): Date {
    const date = new Date(`${value}T00:00:00Z`);
    if (Number.isNaN(date.getTime())) {
      throw new Error(`Invalid ISO date: ${value}`);
    }
    return date;
  }

  private calculateDueDate(task: TaskRecord): Date {
    const lastCompleted = this.parseIsoDate(task.last_completed);
    const dueDate = new Date(lastCompleted);
    dueDate.setUTCDate(dueDate.getUTCDate() + Number(task.cadence_days));
    return dueDate;
  }

  private calculateTaskState(task: TaskRecord) {
    const dueDate = this.calculateDueDate(task);
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);

    const differenceInDays = Math.floor((today.getTime() - dueDate.getTime()) / 86400000);
    const isOverdue = differenceInDays > 0;
    const daysOverdue = isOverdue ? differenceInDays : 0;

    return {
      ...task,
      dueDate: dueDate.toISOString().slice(0, 10),
      isOverdue,
      daysOverdue,
    };
  }

  getTasks(): TaskRecord[] {
    const raw = readFileSync(this.tasksPath, 'utf8');
    const parsed = parse(raw) as TaskRecord[];

    if (!Array.isArray(parsed)) {
      throw new Error('Task registry must be a YAML array');
    }

    return parsed
      .map((task) => this.calculateTaskState(task))
      .sort((a, b) => {
        if (a.isOverdue === b.isOverdue) {
          return a.dueDate!.localeCompare(b.dueDate!);
        }
        return Number(b.isOverdue) - Number(a.isOverdue);
      });
  }
}
