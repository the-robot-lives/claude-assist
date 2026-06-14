import type { MultiSelectQuestion, FeedbackMode } from '../types'

interface Props {
  question: MultiSelectQuestion
  value: string[] | undefined
  onChange: (answer: string[]) => void
  feedbackMode: FeedbackMode
  submitted: boolean
}

export default function MultiSelect({
  question,
  value,
  onChange,
  feedbackMode,
  submitted,
}: Props) {
  const showFeedback = feedbackMode === 'immediate' && submitted
  const selected = value ?? []

  const correctValues = question.correct_answers.map((a) =>
    typeof a === 'number' ? question.options[a] : String(a)
  )

  const toggle = (option: string) => {
    if (selected.includes(option)) {
      onChange(selected.filter((v) => v !== option))
    } else {
      onChange([...selected, option])
    }
  }

  return (
    <div className="mc-options">
      <p className="field-hint">Select all that apply</p>

      {question.options.map((option) => {
        const isSelected = selected.includes(option)
        const isCorrect = correctValues.includes(option)

        let optionClass = 'mc-option'
        if (showFeedback) {
          if (isCorrect) optionClass += ' option-correct'
          else if (isSelected && !isCorrect) optionClass += ' option-incorrect'
        } else if (isSelected) {
          optionClass += ' option-selected'
        }

        return (
          <label key={option} className={optionClass}>
            <input
              type="checkbox"
              checked={isSelected}
              onChange={() => toggle(option)}
              disabled={showFeedback}
            />
            <span>{option}</span>
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
