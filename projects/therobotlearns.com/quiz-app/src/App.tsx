import { useState, useCallback } from 'react'
import type {
  QuizData,
  Question,
  QuizResult,
  QuestionResult,
  AnswerStatus,
} from './types'
import MultipleChoice from './components/MultipleChoice'
import FillInBlank from './components/FillInBlank'
import Matching from './components/Matching'
import TrueFalse from './components/TrueFalse'
import MultiSelect from './components/MultiSelect'
import Results from './components/Results'

type AppState = 'intro' | 'questions' | 'results'

interface Props {
  quizData: QuizData
}

// ── Answer grading helpers ────────────────────────────────────────────────────

function gradeAnswer(question: Question, userAnswer: unknown): AnswerStatus {
  if (userAnswer === null || userAnswer === undefined || userAnswer === '') {
    return 'skipped'
  }

  switch (question.type) {
    case 'multiple_choice': {
      const correct =
        typeof question.correct_answer === 'number'
          ? question.options[question.correct_answer]
          : question.correct_answer
      return userAnswer === correct ? 'correct' : 'incorrect'
    }

    case 'true_false':
      return userAnswer === question.correct_answer ? 'correct' : 'incorrect'

    case 'fill_in_blank': {
      const ua = String(userAnswer).trim()
      const ca = question.correct_answer.trim()
      const compare = question.case_sensitive
        ? (a: string, b: string) => a === b
        : (a: string, b: string) => a.toLowerCase() === b.toLowerCase()
      if (compare(ua, ca)) return 'correct'
      if (question.acceptable_answers?.some((a) => compare(ua, a))) return 'correct'
      return 'incorrect'
    }

    case 'matching': {
      const userMap = userAnswer as Record<string, string>
      const allCorrect = question.pairs.every(
        (pair) => userMap[pair.left] === pair.right
      )
      const anyCorrect = question.pairs.some(
        (pair) => userMap[pair.left] === pair.right
      )
      if (allCorrect) return 'correct'
      if (anyCorrect) return 'partial'
      return 'incorrect'
    }

    case 'multi_select': {
      const userSet = new Set(userAnswer as string[])
      const correctSet = new Set(
        question.correct_answers.map((a) =>
          typeof a === 'number' ? question.options[a] : String(a)
        )
      )
      const allMatch =
        userSet.size === correctSet.size &&
        [...userSet].every((v) => correctSet.has(v))
      if (allMatch) return 'correct'
      const anyMatch = [...userSet].some((v) => correctSet.has(v))
      if (anyMatch) return 'partial'
      return 'incorrect'
    }

    case 'ordering': {
      const userOrder = userAnswer as number[]
      const allCorrect = userOrder.every(
        (v, i) => v === question.correct_order[i]
      )
      return allCorrect ? 'correct' : 'incorrect'
    }

    case 'short_answer':
      // Short answer is always marked as partial — manual review needed
      return 'partial'

    default:
      return 'skipped'
  }
}

function getCorrectDisplay(question: Question): unknown {
  switch (question.type) {
    case 'multiple_choice':
      return typeof question.correct_answer === 'number'
        ? question.options[question.correct_answer]
        : question.correct_answer
    case 'true_false':
      return question.correct_answer ? 'True' : 'False'
    case 'fill_in_blank':
      return question.correct_answer
    case 'matching':
      return question.pairs.map((p) => `${p.left} → ${p.right}`).join(', ')
    case 'multi_select':
      return question.correct_answers
        .map((a) =>
          typeof a === 'number' ? question.options[a] : String(a)
        )
        .join(', ')
    case 'ordering':
      return question.correct_order.map((i) => question.items[i]).join(' → ')
    case 'short_answer':
      return question.sample_answer
    default:
      return ''
  }
}

// ── Main component ────────────────────────────────────────────────────────────

export default function App({ quizData }: Props) {
  const [appState, setAppState] = useState<AppState>('intro')
  const [currentIndex, setCurrentIndex] = useState(0)
  const [answers, setAnswers] = useState<Record<string, unknown>>({})
  const [result, setResult] = useState<QuizResult | null>(null)
  const [startTime, setStartTime] = useState<number>(0)

  const questions = quizData.questions
  const feedbackMode = quizData.feedback_mode ?? 'end'
  const passingScore = quizData.passing_score ?? 70

  const currentQuestion = questions[currentIndex]
  const progress = ((currentIndex) / questions.length) * 100

  const handleStart = () => {
    setStartTime(Date.now())
    setAppState('questions')
  }

  const handleAnswer = useCallback(
    (answer: unknown) => {
      setAnswers((prev) => ({ ...prev, [currentQuestion.id]: answer }))
    },
    [currentQuestion]
  )

  const handleNext = useCallback(() => {
    if (currentIndex < questions.length - 1) {
      setCurrentIndex((i) => i + 1)
    } else {
      // Build results
      const timeTaken = Math.round((Date.now() - startTime) / 1000)
      const questionResults: QuestionResult[] = questions.map((q) => {
        const userAnswer = answers[q.id] ?? null
        const status = gradeAnswer(q, userAnswer)
        return {
          question_id: q.id,
          question_type: q.type,
          question_text: q.question,
          user_answer: userAnswer,
          correct_answer: getCorrectDisplay(q),
          status,
          topic: q.topic,
        }
      })

      const correct = questionResults.filter((r) => r.status === 'correct').length
      const partial = questionResults.filter((r) => r.status === 'partial').length
      const total = questions.length
      const rawScore = correct + partial * 0.5
      const scorePercent = Math.round((rawScore / total) * 100)

      // Identify weak topics
      const topicStats: Record<string, { correct: number; total: number }> = {}
      questionResults.forEach((r) => {
        const topic = r.topic ?? 'General'
        if (!topicStats[topic]) topicStats[topic] = { correct: 0, total: 0 }
        topicStats[topic].total++
        if (r.status === 'correct') topicStats[topic].correct++
      })
      const weakAreas = Object.entries(topicStats)
        .filter(([, s]) => s.correct / s.total < 0.6)
        .map(([topic]) => topic)

      const quizResult: QuizResult = {
        quiz_id: quizData.quiz_id,
        title: quizData.title,
        score: scorePercent,
        raw_correct: correct,
        raw_total: total,
        passed: scorePercent >= passingScore,
        passing_score: passingScore,
        completed_at: new Date().toISOString(),
        time_taken_seconds: timeTaken,
        questions: questionResults,
        weak_areas: weakAreas,
      }

      setResult(quizResult)
      setAppState('results')
    }
  }, [currentIndex, questions, answers, startTime, quizData, passingScore])

  const handleRetry = () => {
    setAnswers({})
    setCurrentIndex(0)
    setResult(null)
    setAppState('intro')
  }

  // ── Intro screen ────────────────────────────────────────────────────────────
  if (appState === 'intro') {
    return (
      <div className="quiz-shell">
        <div className="quiz-card intro-card">
          <h1 className="quiz-title">{quizData.title}</h1>
          {quizData.description && (
            <p className="quiz-description">{quizData.description}</p>
          )}
          <div className="intro-meta">
            <span>{questions.length} questions</span>
            {quizData.time_limit_seconds && (
              <span>{Math.round(quizData.time_limit_seconds / 60)} min limit</span>
            )}
            <span>Pass at {passingScore}%</span>
          </div>
          <button className="btn-primary" onClick={handleStart}>
            Start Quiz
          </button>
        </div>
      </div>
    )
  }

  // ── Results screen ──────────────────────────────────────────────────────────
  if (appState === 'results' && result) {
    return (
      <div className="quiz-shell">
        <Results result={result} onRetry={handleRetry} />
      </div>
    )
  }

  // ── Question screen ─────────────────────────────────────────────────────────
  const currentAnswer = answers[currentQuestion.id]
  const hasAnswer =
    currentAnswer !== undefined && currentAnswer !== null && currentAnswer !== ''

  return (
    <div className="quiz-shell">
      {/* Progress bar */}
      <div className="progress-container">
        <div className="progress-bar" style={{ width: `${progress}%` }} />
      </div>
      <div className="progress-label">
        Question {currentIndex + 1} of {questions.length}
      </div>

      <div className="quiz-card question-card">
        {currentQuestion.topic && (
          <span className="topic-badge">{currentQuestion.topic}</span>
        )}
        {currentQuestion.difficulty && (
          <span className={`difficulty-badge difficulty-${currentQuestion.difficulty}`}>
            {currentQuestion.difficulty}
          </span>
        )}

        <p className="question-text">{currentQuestion.question}</p>

        {/* Render the right input component */}
        {currentQuestion.type === 'multiple_choice' && (
          <MultipleChoice
            question={currentQuestion}
            value={currentAnswer as string | undefined}
            onChange={handleAnswer}
            feedbackMode={feedbackMode}
            submitted={false}
          />
        )}
        {currentQuestion.type === 'true_false' && (
          <TrueFalse
            question={currentQuestion}
            value={currentAnswer as boolean | undefined}
            onChange={handleAnswer}
            feedbackMode={feedbackMode}
            submitted={false}
          />
        )}
        {currentQuestion.type === 'fill_in_blank' && (
          <FillInBlank
            question={currentQuestion}
            value={currentAnswer as string | undefined}
            onChange={handleAnswer}
            feedbackMode={feedbackMode}
            submitted={false}
          />
        )}
        {currentQuestion.type === 'matching' && (
          <Matching
            question={currentQuestion}
            value={currentAnswer as Record<string, string> | undefined}
            onChange={handleAnswer}
            feedbackMode={feedbackMode}
            submitted={false}
          />
        )}
        {currentQuestion.type === 'multi_select' && (
          <MultiSelect
            question={currentQuestion}
            value={currentAnswer as string[] | undefined}
            onChange={handleAnswer}
            feedbackMode={feedbackMode}
            submitted={false}
          />
        )}
        {currentQuestion.type === 'short_answer' && (
          <FillInBlank
            question={currentQuestion}
            value={currentAnswer as string | undefined}
            onChange={handleAnswer}
            feedbackMode={feedbackMode}
            submitted={false}
          />
        )}
        {currentQuestion.type === 'ordering' && (
          <div className="ordering-note">
            <p className="field-hint">
              Ordering questions — answer recorded as-is. (UI support coming soon.)
            </p>
            <textarea
              className="text-input"
              placeholder="Type the correct order, one item per line…"
              value={(currentAnswer as string) ?? ''}
              onChange={(e) => handleAnswer(e.target.value)}
              rows={4}
            />
          </div>
        )}

        <div className="question-footer">
          <button
            className="btn-primary"
            onClick={handleNext}
            disabled={!hasAnswer}
          >
            {currentIndex < questions.length - 1 ? 'Next →' : 'Finish Quiz'}
          </button>
        </div>
      </div>
    </div>
  )
}
