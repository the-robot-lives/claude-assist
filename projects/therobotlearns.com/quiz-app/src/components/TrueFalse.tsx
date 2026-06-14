import type { TrueFalseQuestion, FeedbackMode } from '../types'

interface Props {
  question: TrueFalseQuestion
  value: boolean | undefined
  onChange: (answer: boolean) => void
  feedbackMode: FeedbackMode
  submitted: boolean
}

export default function TrueFalse({
  question,
  value,
  onChange,
  feedbackMode,
  submitted,
}: Props) {
  const showFeedback = feedbackMode === 'immediate' && submitted

  const opts: { label: string; val: boolean }[] = [
    { label: 'True', val: true },
    { label: 'False', val: false },
  ]

  return (
    <div className="mc-options">
      {opts.map(({ label, val }) => {
        const isSelected = value === val
        const isCorrect = val === question.correct_answer

        let optionClass = 'mc-option'
        if (showFeedback) {
          if (isCorrect) optionClass += ' option-correct'
          else if (isSelected && !isCorrect) optionClass += ' option-incorrect'
        } else if (isSelected) {
          optionClass += ' option-selected'
        }

        return (
          <label key={label} className={optionClass}>
            <input
              type="radio"
              name={question.id}
              checked={isSelected}
              onChange={() => onChange(val)}
              disabled={showFeedback}
            />
            <span>{label}</span>
            {showFeedback && isCorrect && (
              <span className="feedback-icon feedback-correct">✓</span>
            )}
            {showFeedback && isSelected && !isCorrect && (
              <span className="feedback-icon feedback-incorrect">✗</span>
            )}
          </label>
        )
      })}

      {showFeedback && question.explanation && (
        <div className="explanation-box">{question.explanation}</div>
      )}
    </div>
  )
}
