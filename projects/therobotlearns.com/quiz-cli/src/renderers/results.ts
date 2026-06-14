import chalk from 'chalk';
import type { QuizResult, QuestionResult } from '../types.js';

function formatDuration(ms: number): string {
  const s = Math.floor(ms / 1000);
  const m = Math.floor(s / 60);
  if (m > 0) return `${m}m ${s % 60}s`;
  return `${s}s`;
}

function scoreColor(score: number, passed: boolean): chalk.Chalk {
  if (passed) return chalk.green;
  if (score >= 50) return chalk.yellow;
  return chalk.red;
}

function resultRow(r: QuestionResult, index: number): string {
  const icon = r.correct ? chalk.green('✓') : chalk.red('✗');
  const label = r.questionText.length > 48
    ? r.questionText.slice(0, 45) + '...'
    : r.questionText.padEnd(48);
  const time = chalk.dim(`${r.elapsedMs}ms`);
  return `  ${icon}  ${label}  ${time}`;
}

export function displayResults(result: QuizResult): void {
  const color = scoreColor(result.score, result.passed);
  const passLabel = result.passed
    ? chalk.bold.green(' PASSED ')
    : chalk.bold.red(' FAILED ');

  console.log('\n' + chalk.bold.cyan('━'.repeat(60)));
  console.log(chalk.bold.white('  RESULTS'));
  console.log(chalk.bold.cyan('━'.repeat(60)));

  console.log(
    `\n  Score:    ${color.bold(`${result.score}%`)}  ${passLabel}`,
  );
  console.log(
    `  Correct:  ${chalk.white(result.correctCount)} / ${chalk.white(result.totalQuestions)}`,
  );
  console.log(`  Time:     ${chalk.white(formatDuration(result.durationMs))}`);

  console.log('\n' + chalk.dim('  ─'.repeat(30)));
  console.log(chalk.dim('  Per-question breakdown:\n'));
  result.results.forEach((r, i) => console.log(resultRow(r, i)));

  if (result.weakAreas.length > 0) {
    console.log('\n' + chalk.dim('  ─'.repeat(30)));
    console.log(chalk.yellow.bold('  Weak areas (< 60% accuracy):'));
    for (const area of result.weakAreas) {
      console.log(chalk.yellow(`    • ${area}`));
    }
  }

  console.log('\n' + chalk.bold.cyan('━'.repeat(60)) + '\n');
}

export function formatResultsJson(result: QuizResult): string {
  return JSON.stringify(result, null, 2);
}
