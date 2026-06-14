// ── Question Types ────────────────────────────────────────────────────────────

export interface MultipleChoiceQuestion {
  type: 'multiple_choice'
  id: string
  question: string
  options: string[]
  correct_answer: string | number  // index or value
  explanation?: string
  topic?: string
  difficulty?: 'easy' | 'medium' | 'hard'
}

export interface FillInBlankQuestion {
  type: 'fill_in_blank'
  id: string
  question: string
  correct_answer: string
  acceptable_answers?: string[]
  case_sensitive?: boolean
  explanation?: string
  topic?: string
  difficulty?: 'easy' | 'medium' | 'hard'
}

export interface MatchingPair {
  left: string
  right: string
}

export interface MatchingQuestion {
  type: 'matching'
  id: string
  question: string
  pairs: MatchingPair[]
  explanation?: string
  topic?: string
  difficulty?: 'easy' | 'medium' | 'hard'
}

export interface ShortAnswerQuestion {
  type: 'short_answer'
  id: string
  question: string
  sample_answer: string
  keywords?: string[]
  explanation?: string
  topic?: string
  difficulty?: 'easy' | 'medium' | 'hard'
}

export interface TrueFalseQuestion {
  type: 'true_false'
  id: string
  question: string
  correct_answer: boolean
  explanation?: string
  topic?: string
  difficulty?: 'easy' | 'medium' | 'hard'
}

export interface OrderingQuestion {
  type: 'ordering'
  id: string
  question: string
  items: string[]
  correct_order: number[]  // indices into items[]
  explanation?: string
  topic?: string
  difficulty?: 'easy' | 'medium' | 'hard'
}

export interface MultiSelectQuestion {
  type: 'multi_select'
  id: string
  question: string
  options: string[]
  correct_answers: (string | number)[]  // indices or values
  explanation?: string
  topic?: string
  difficulty?: 'easy' | 'medium' | 'hard'
}

export type Question =
  | MultipleChoiceQuestion
  | FillInBlankQuestion
  | MatchingQuestion
  | ShortAnswerQuestion
  | TrueFalseQuestion
  | OrderingQuestion
  | MultiSelectQuestion

// ── Quiz Data ─────────────────────────────────────────────────────────────────

export type FeedbackMode = 'immediate' | 'end' | 'none'

export interface QuizData {
  quiz_id: string
  title: string
  description?: string
  questions: Question[]
  passing_score?: number          // 0–100
  feedback_mode?: FeedbackMode
  shuffle_questions?: boolean
  shuffle_options?: boolean
  time_limit_seconds?: number
  tags?: string[]
}

// ── Results ───────────────────────────────────────────────────────────────────

export type AnswerStatus = 'correct' | 'incorrect' | 'partial' | 'skipped'

export interface QuestionResult {
  question_id: string
  question_type: Question['type']
  question_text: string
  user_answer: unknown
  correct_answer: unknown
  status: AnswerStatus
  topic?: string
}

export interface QuizResult {
  quiz_id: string
  title: string
  score: number                   // 0–100
  raw_correct: number
  raw_total: number
  passed: boolean
  passing_score: number
  completed_at: string            // ISO timestamp
  time_taken_seconds?: number
  questions: QuestionResult[]
  weak_areas: string[]            // topics where user struggled
}

// ── Global augment for the data injection bridge ─────────────────────────────

declare global {
  interface Window {
    __QUIZ_DATA__?: QuizData
  }
}
