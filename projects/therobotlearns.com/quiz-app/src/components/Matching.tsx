import type { MatchingQuestion, FeedbackMode } from '../types'

interface Props {
  question: MatchingQuestion
  value: Record<string, string> | undefined
  onChange: (answer: Record<string, string>) => void
  feedbackMode: FeedbackMode
  submitted: boolean
}

export default function Matching({
  question,
  value,
  onChange,
  feedbackMode,
  submitted,
}: Props) {
  const showFeedback = feedbackMode === 'immediate' && submitted
  const current = value ?? {}

  // Shuffle right-side options for display (stable order from pairs)
  const rightOptions = question.pairs.map((p) => p.right)

  const handleChange = (leftItem: string, selectedRight: string) => {
    onChange({ ...current, [leftItem]: selectedRight })
  }

  return (
    <div className="matching-container">
      <div className="matching-header">
        <span>Item</span>
        <span>Match</span>
      </div>

      {question.pairs.map((pair) => {
        const selected = current[pair.left] ?? ''
        const isCorrect = selected === pair.right
        const showRowFeedback = showFeedback && selected !== ''

        let rowClass = 'matching-row'
        if (showRowFeedback) {
          rowClass += isCorrect ? ' option-correct' : ' option-incorrect'
        }

        return (
          <div key={pair.left} className={rowClass}>
            <span className="matching-left">{pair.left}</span>
            <div className="matching-right-wrapper">
              <select
                className="matching-select"
                value={selected}
                onChange={(e) => handleChange(pair.left, e.target.value)}
                disabled={showFeedback}
              >
                <option value="">— select —</option>
                {rightOptions.map((opt) => (
                  <option key={opt} value={opt}>
                    {opt}
                  </option>
                ))}
              </select>
              {showRowFeedback && (
                <span
                  className={`feedback-icon ${isCorrect ? 'feedback-correct' : 'feedback-incorrect'}`}
                >
                  {isCorrect ? '✓' : '✗'}
                </span>
              )}
            </div>
            {showFeedback && !isCorrect && (
              <span className="matching-correct-hint">→ {pair.right}</span>
            )}
          </div>
        )
      })}

      {showFeedback && question.explanation && (
        <div className="explanation-box">{question.explanation}</div>
      )}
    </div>
  )
}
