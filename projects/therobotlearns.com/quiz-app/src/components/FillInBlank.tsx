import type { FillInBlankQuestion, ShortAnswerQuestion, FeedbackMode } from '../types'

interface Props {
  question: FillInBlankQuestion | ShortAnswerQuestion
  value: string | undefined
  onChange: (answer: string) => void
  feedbackMode: FeedbackMode
  submitted: boolean
}

export default function FillInBlank({
  question,
  value,
  onChange,
  feedbackMode,
  submitted,
}: Props) {
  const showFeedback = feedbackMode === 'immediate' && submitted
  const isShortAnswer = question.type === 'short_answer'

  return (
    <div className="fill-blank-container">
      {isShortAnswer ? (
        <textarea
          className="text-input"
          placeholder="Type your answer…"
          value={value ?? ''}
          onChange={(e) => onChange(e.target.value)}
          disabled={showFeedback}
          rows={4}
        />
      ) : (
        <input
          type="text"
          className="text-input"
          placeholder="Type your answer…"
          value={value ?? ''}
          onChange={(e) => onChange(e.target.value)}
          disabled={showFeedback}
        />
      )}

      {showFeedback && question.type === 'fill_in_blank' && (
        <div className="explanation-box">
          <strong>Correct answer:</strong> {question.correct_answer}
          {question.acceptable_answers && question.acceptable_answers.length > 0 && (
            <span> (also: {question.acceptable_answers.join(', ')})</span>
          )}
          {question.explanation && <p>{question.explanation}</p>}
        </div>
      )}

      {showFeedback && question.type === 'short_answer' && (
        <div className="explanation-box">
          <strong>Sample answer:</strong> {question.sample_answer}
          {question.keywords && question.keywords.length > 0 && (
            <p><strong>Key concepts:</strong> {question.keywords.join(', ')}</p>
          )}
        </div>
      )}
    </div>
  )
}
