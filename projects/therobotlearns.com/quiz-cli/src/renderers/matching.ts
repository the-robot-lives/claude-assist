import { select } from '@inquirer/prompts';
import chalk from 'chalk';
import type { MatchingQuestion, QuestionResult } from '../types.js';

export async function renderMatching(
  question: MatchingQuestion,
  startMs: number,
): Promise<QuestionResult> {
  console.log(chalk.bold(`\n  ${question.text}`));
  console.log(chalk.dim('  Match each item on the left to the correct answer.\n'));

  const rightOptions = question.pairs.map((p) => p.right);
  const remaining = new Set(rightOptions);

  const userMatches: Record<string, string> = {};
  const correctMatches: Record<string, string> = {};

  for (const pair of question.pairs) {
    correctMatches[pair.left] = pair.right;
  }

  for (const pair of question.pairs) {
    const availableChoices = [...remaining].map((opt) => ({
      name: opt,
      value: opt,
    }));

    const chosen = await select({
      message: `  ${pair.left}  →`,
      choices: availableChoices,
    });

    userMatches[pair.left] = chosen;
    remaining.delete(chosen);
  }

  // Score: all pairs must match
  const allCorrect = question.pairs.every(
    (pair) => userMatches[pair.left] === pair.right,
  );

  return {
    questionId: question.id,
    questionText: question.text,
    type: 'matching',
    correct: allCorrect,
    userAnswer: userMatches,
    correctAnswer: correctMatches,
    tags: question.tags,
    elapsedMs: Date.now() - startMs,
  };
}
