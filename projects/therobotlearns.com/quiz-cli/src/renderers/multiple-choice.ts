import { select } from '@inquirer/prompts';
import type { MultipleChoiceQuestion, QuestionResult } from '../types.js';

export async function renderMultipleChoice(
  question: MultipleChoiceQuestion,
  startMs: number,
): Promise<QuestionResult> {
  const answer = await select({
    message: question.text,
    choices: question.options.map((opt) => ({ name: opt, value: opt })),
  });

  const correct =
    answer.trim().toLowerCase() === question.answer.trim().toLowerCase();

  return {
    questionId: question.id,
    questionText: question.text,
    type: 'multiple-choice',
    correct,
    userAnswer: answer,
    correctAnswer: question.answer,
    tags: question.tags,
    elapsedMs: Date.now() - startMs,
  };
}
