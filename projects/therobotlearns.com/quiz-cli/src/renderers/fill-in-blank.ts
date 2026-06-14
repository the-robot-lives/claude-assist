import { input } from '@inquirer/prompts';
import type { FillInBlankQuestion, QuestionResult } from '../types.js';

function normalize(s: string): string {
  return s.trim().toLowerCase().replace(/\s+/g, ' ');
}

export async function renderFillInBlank(
  question: FillInBlankQuestion,
  startMs: number,
): Promise<QuestionResult> {
  // Display text with blank highlighted
  const displayText = question.text.replace(/___+/g, '______');

  const answer = await input({
    message: displayText,
  });

  const normalizedAnswer = normalize(answer);
  const accepted = [
    question.answer,
    ...(question.acceptedAnswers ?? []),
  ].map(normalize);

  const correct = accepted.includes(normalizedAnswer);

  return {
    questionId: question.id,
    questionText: question.text,
    type: 'fill-in-blank',
    correct,
    userAnswer: answer,
    correctAnswer: question.answer,
    tags: question.tags,
    elapsedMs: Date.now() - startMs,
  };
}
