#!/usr/bin/env node
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { parse as parseYaml } from 'yaml';
import { runQuiz } from '../runner.js';
import type { QuizData } from '../types.js';

function parseArgs(argv: string[]): { quizPath: string; outputPath?: string } {
  const args = argv.slice(2);

  if (args.length === 0) {
    console.error('Usage: quiz <path-to-quiz.yaml> [--output <results.json>]');
    process.exit(1);
  }

  const quizPath = args[0];
  let outputPath: string | undefined;

  const outputIdx = args.indexOf('--output');
  if (outputIdx !== -1 && args[outputIdx + 1]) {
    outputPath = args[outputIdx + 1];
  }

  return { quizPath, outputPath };
}

async function main() {
  const { quizPath, outputPath } = parseArgs(process.argv);

  let raw: string;
  try {
    raw = readFileSync(resolve(quizPath), 'utf-8');
  } catch {
    console.error(`Error: Cannot read file "${quizPath}"`);
    process.exit(1);
  }

  let quizData: QuizData;
  try {
    quizData = parseYaml(raw) as QuizData;
  } catch (err) {
    console.error(`Error: Failed to parse YAML — ${(err as Error).message}`);
    process.exit(1);
  }

  if (!quizData.questions || quizData.questions.length === 0) {
    console.error('Error: Quiz has no questions.');
    process.exit(1);
  }

  const result = await runQuiz(quizData);

  const json = JSON.stringify(result, null, 2);

  if (outputPath) {
    writeFileSync(resolve(outputPath), json, 'utf-8');
    console.log(`\nResults written to ${outputPath}`);
  } else {
    process.stdout.write('\n' + json + '\n');
  }
}

main().catch((err: unknown) => {
  console.error('Unexpected error:', err);
  process.exit(1);
});
