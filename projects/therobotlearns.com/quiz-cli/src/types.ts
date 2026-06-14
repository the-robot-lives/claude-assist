// ─── Question Variants ────────────────────────────────────────────────────────

export interface MultipleChoiceQuestion {
  type: 'multiple-choice';
  id: string;
  text: string;
  options: string[];
  answer: string;
  explanation?: string;
  tags?: string[];
}

export interface FillInBlankQuestion {
  type: 'fill-in-blank';
  id: string;
  text: string; // Use ___ to mark the blank
  answer: string;
  acceptedAnswers?: string[]; // alternate correct spellings / phrasings
  explanation?: string;
  tags?: string[];
}

export interface MatchingQuestion {
  type: 'matching';
  id: string;
  text: string;
  pairs: Array<{ left: string; right: string }>;
  explanation?: string;
  tags?: string[];
}

export type Question =
  | MultipleChoiceQuestion
  | FillInBlankQuestion
  | MatchingQuestion;

// ─── Quiz Data (top-level YAML shape) ────────────────────────────────────────

export interface QuizData {
  id: string;
  title: string;
  description?: string;
  passingScore?: number; // 0-100, default 70
  questions: Question[];
}

// ─── Results ─────────────────────────────────────────────────────────────────

export interface QuestionResult {
  questionId: string;
  questionText: string;
  type: Question['type'];
  correct: boolean;
  userAnswer: string | Record<string, string>;
  correctAnswer: string | Record<string, string>;
  tags?: string[];
  elapsedMs: number;
}

export interface QuizResult {
  quizId: string;
  quizTitle: string;
  score: number; // 0-100
  passed: boolean;
  totalQuestions: number;
  correctCount: number;
  durationMs: number;
  results: QuestionResult[];
  weakAreas: string[]; // tags with < 60% accuracy
  completedAt: string; // ISO 8601
}
