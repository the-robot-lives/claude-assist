import type { MultipleChoiceQuestion, FeedbackMode } from '../types'

interface Props {
  question: MultipleChoiceQuestion
  value: string | undefined
  onChange: (answer: string) => void
  feedbackMode: FeedbackMode
  submitted: boolean
}

export default function MultipleChoice({
  question,
  value,
  onChange,
  feedbackMode,
  submitted,
}: Props) {
  const correctValue =
    typeof question.correct_answer === 'number'
      ? question.options[question.correct_answer]
      : question.correct_answer

  const showFeedback = feedbackMode === 'immediate' && submitted

  return (
    <div className="mc-options">
      {question.options.map((option) => {
        const isSelected = value === option
        const isCorrect = option === correctValue

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
              type="radio"
              name={question.id}
              value={option}
              checked={isSelected}
              onChange={() => onChange(option)}
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
