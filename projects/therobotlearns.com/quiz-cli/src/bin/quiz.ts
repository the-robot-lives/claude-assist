#!/usr/bin/env node
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { parse as parseYaml } from 'yaml';
import { runQuiz } from '../runner.js';
import type { QuizData, Question } from '../types.js';

function parseArgs(argv: string[]): { quizPath: string; outputPath?: string; dryRun: boolean } {
  const args = argv.slice(2);

  if (args.length === 0) {
    console.error('Usage: quiz <path-to-quiz.yaml> [--output <results.json>] [--dry-run]');
    process.exit(1);
  }

  const quizPath = args[0];
  let outputPath: string | undefined;
  const dryRun = args.includes('--dry-run');

  const outputIdx = args.indexOf('--output');
  if (outputIdx !== -1 && args[outputIdx + 1]) {
    outputPath = args[outputIdx + 1];
  }

  return { quizPath, outputPath, dryRun };
}

function normalizeQuizData(raw: Record<string, unknown>): QuizData {
  const rawQuestions = Array.isArray(raw.questions) ? raw.questions as Array<Record<string, unknown>> : [];
  const questions = rawQuestions.map((q, index): Question => {
    const id = String(q.id ?? `q${index + 1}`);
    const text = String(q.text ?? q.question ?? q.prompt ?? '');
    const explanation = typeof q.explanation === 'string' ? q.explanation : undefined;
    const tags = Array.isArray(q.tags)
      ? q.tags.map(String)
      : q.topic
        ? [String(q.topic)]
        : undefined;
    const type = String(q.type ?? q.spa_type ?? '').replace(/_/g, '-');

    if (type === 'multiple-choice') {
      return {
        type: 'multiple-choice',
        id,
        text,
        options: (Array.isArray(q.options) ? q.options : []).map(String),
        answer: String(q.answer ?? q.correct_answer ?? q.correct ?? ''),
        explanation,
        tags,
      };
    }

    if (type === 'true-false') {
      const answer = Boolean(q.answer ?? q.correct_answer ?? q.correct);
      return {
        type: 'multiple-choice',
        id,
        text,
        options: ['True', 'False'],
        answer: answer ? 'True' : 'False',
        explanation,
        tags,
      };
    }

    if (type === 'matching') {
      return {
        type: 'matching',
        id,
        text,
        pairs: Array.isArray(q.pairs) ? q.pairs as Array<{ left: string; right: string }> : [],
        explanation,
        tags,
      };
    }

    return {
      type: 'fill-in-blank',
      id,
      text,
      answer: String(q.answer ?? q.correct_answer ?? q.correct ?? ''),
      acceptedAnswers: [
        ...(
          Array.isArray(q.acceptedAnswers)
            ? q.acceptedAnswers
            : Array.isArray(q.acceptable_answers)
              ? q.acceptable_answers
              : Array.isArray(q.accept_also)
                ? q.accept_also
                : []
        ),
      ].map(String),
      explanation,
      tags,
    };
  });

  return {
    id: String(raw.id ?? raw.quiz_id ?? 'quiz'),
    title: String(raw.title ?? 'Quiz'),
    description: typeof raw.description === 'string' ? raw.description : undefined,
    passingScore: Number(raw.passingScore ?? raw.passing_score ?? 70),
    questions,
  };
}

async function main() {
  const { quizPath, outputPath, dryRun } = parseArgs(process.argv);

  let raw: string;
  try {
    raw = readFileSync(resolve(quizPath), 'utf-8');
  } catch {
    console.error(`Error: Cannot read file "${quizPath}"`);
    process.exit(1);
  }

  let quizData: QuizData;
  try {
    quizData = normalizeQuizData(parseYaml(raw) as Record<string, unknown>);
  } catch (err) {
    console.error(`Error: Failed to parse YAML — ${(err as Error).message}`);
    process.exit(1);
  }

  if (!quizData.questions || quizData.questions.length === 0) {
    console.error('Error: Quiz has no questions.');
    process.exit(1);
  }

  if (dryRun) {
    console.log(`Quiz OK: ${quizData.title} (${quizData.questions.length} questions)`);
    return;
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
