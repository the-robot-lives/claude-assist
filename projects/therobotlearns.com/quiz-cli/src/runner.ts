import chalk from 'chalk';
import type { QuizData, QuizResult, QuestionResult, Question } from './types.js';
import { renderMultipleChoice } from './renderers/multiple-choice.js';
import { renderFillInBlank } from './renderers/fill-in-blank.js';
import { renderMatching } from './renderers/matching.js';
import { displayResults } from './renderers/results.js';

function computeWeakAreas(results: QuestionResult[]): string[] {
  const tagStats: Record<string, { correct: number; total: number }> = {};

  for (const r of results) {
    for (const tag of r.tags ?? []) {
      if (!tagStats[tag]) tagStats[tag] = { correct: 0, total: 0 };
      tagStats[tag].total++;
      if (r.correct) tagStats[tag].correct++;
    }
  }

  return Object.entries(tagStats)
    .filter(([, s]) => s.total > 0 && s.correct / s.total < 0.6)
    .map(([tag]) => tag);
}

async function runQuestion(
  question: Question,
  index: number,
  total: number,
): Promise<QuestionResult> {
  console.log(
    chalk.dim(`\nQuestion ${index + 1} of ${total}`) +
      (question.tags?.length
        ? chalk.dim(`  [${question.tags.join(', ')}]`)
        : ''),
  );

  const start = Date.now();

  switch (question.type) {
    case 'multiple-choice':
      return renderMultipleChoice(question, start);
    case 'fill-in-blank':
      return renderFillInBlank(question, start);
    case 'matching':
      return renderMatching(question, start);
  }
}

export async function runQuiz(quiz: QuizData): Promise<QuizResult> {
  const passingScore = quiz.passingScore ?? 70;
  const quizStart = Date.now();

  console.log('\n' + chalk.bold.cyan('━'.repeat(60)));
  console.log(chalk.bold.white(` ${quiz.title}`));
  if (quiz.description) {
    console.log(chalk.gray(` ${quiz.description}`));
  }
  console.log(
    chalk.dim(
      ` ${quiz.questions.length} question${quiz.questions.length !== 1 ? 's' : ''}  •  passing score: ${passingScore}%`,
    ),
  );
  console.log(chalk.bold.cyan('━'.repeat(60)));

  const questionResults: QuestionResult[] = [];

  for (let i = 0; i < quiz.questions.length; i++) {
    const result = await runQuestion(quiz.questions[i], i, quiz.questions.length);
    questionResults.push(result);

    if (result.correct) {
      console.log(chalk.green('  ✓ Correct'));
    } else {
      console.log(chalk.red('  ✗ Incorrect'));
      console.log(
        chalk.dim(`    Correct answer: `) +
          chalk.yellow(
            typeof result.correctAnswer === 'string'
              ? result.correctAnswer
              : JSON.stringify(result.correctAnswer),
          ),
      );
    }

    if (quiz.questions[i].explanation) {
      console.log(chalk.dim(`    ${quiz.questions[i].explanation}`));
    }
  }

  const correctCount = questionResults.filter((r) => r.correct).length;
  const score = Math.round((correctCount / quiz.questions.length) * 100);
  const passed = score >= passingScore;
  const durationMs = Date.now() - quizStart;
  const weakAreas = computeWeakAreas(questionResults);

  const quizResult: QuizResult = {
    quizId: quiz.id,
    quizTitle: quiz.title,
    score,
    passed,
    totalQuestions: quiz.questions.length,
    correctCount,
    durationMs,
    results: questionResults,
    weakAreas,
    completedAt: new Date().toISOString(),
  };

  displayResults(quizResult);

  return quizResult;
}
