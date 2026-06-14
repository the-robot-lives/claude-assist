import { useState } from 'react'
import type { QuizResult, AnswerStatus } from '../types'

interface Props {
  result: QuizResult
  onRetry: () => void
}

const STATUS_LABEL: Record<AnswerStatus, string> = {
  correct: '✓',
  incorrect: '✗',
  partial: '~',
  skipped: '—',
}

const STATUS_CLASS: Record<AnswerStatus, string> = {
  correct: 'status-correct',
  incorrect: 'status-incorrect',
  partial: 'status-partial',
  skipped: 'status-skipped',
}

export default function Results({ result, onRetry }: Props) {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(JSON.stringify(result, null, 2))
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch {
      // Fallback for browsers that block clipboard without user gesture
      const ta = document.createElement('textarea')
      ta.value = JSON.stringify(result, null, 2)
      document.body.appendChild(ta)
      ta.select()
      document.execCommand('copy')
      document.body.removeChild(ta)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    }
  }

  const passClass = result.passed ? 'pass-badge pass' : 'pass-badge fail'

  return (
    <div className="results-container">
      <div className="results-header">
        <h2 className="results-title">{result.title}</h2>
        <div className={passClass}>{result.passed ? 'PASSED' : 'FAILED'}</div>
      </div>

      {/* Score summary */}
      <div className="score-summary">
        <div className="score-big">{result.score}%</div>
        <div className="score-detail">
          {result.raw_correct} / {result.raw_total} correct
          {result.time_taken_seconds !== undefined && (
            <span className="time-detail">
              &nbsp;· {Math.floor(result.time_taken_seconds / 60)}m{' '}
              {result.time_taken_seconds % 60}s
            </span>
          )}
        </div>
        <div className="score-passing">Passing score: {result.passing_score}%</div>
      </div>

      {/* Weak areas */}
      {result.weak_areas.length > 0 && (
        <div className="weak-areas">
          <h3>Areas to review</h3>
          <ul>
            {result.weak_areas.map((area) => (
              <li key={area}>{area}</li>
            ))}
          </ul>
        </div>
      )}

      {/* Per-question breakdown */}
      <div className="breakdown">
        <h3>Question Breakdown</h3>
        <table className="breakdown-table">
          <thead>
            <tr>
              <th>#</th>
              <th>Question</th>
              <th>Your Answer</th>
              <th>Correct</th>
              <th>Result</th>
            </tr>
          </thead>
          <tbody>
            {result.questions.map((q, i) => (
              <tr key={q.question_id} className={STATUS_CLASS[q.status]}>
                <td>{i + 1}</td>
                <td className="q-text">{q.question_text}</td>
                <td>{String(q.user_answer ?? '—')}</td>
                <td>{String(q.correct_answer ?? '—')}</td>
                <td className="status-cell">
                  <span className={`status-icon ${STATUS_CLASS[q.status]}`}>
                    {STATUS_LABEL[q.status]}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Action buttons */}
      <div className="results-actions">
        <button className="btn-copy" onClick={handleCopy}>
          {copied ? 'Copied!' : 'Copy Results JSON'}
        </button>
        <button className="btn-secondary" onClick={onRetry}>
          Retry Quiz
        </button>
      </div>
    </div>
  )
}
