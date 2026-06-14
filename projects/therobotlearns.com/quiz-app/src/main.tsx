import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './styles.css'
import App from './App'

const root = document.getElementById('root')
if (!root) throw new Error('No #root element found')

const quizData = window.__QUIZ_DATA__

if (!quizData) {
  root.innerHTML = `
    <div style="
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      font-family: system-ui, sans-serif;
      color: #ef4444;
      text-align: center;
      padding: 2rem;
    ">
      <h1 style="font-size: 1.5rem; margin-bottom: 0.5rem;">No Quiz Data Found</h1>
      <p style="color: #6b7280; max-width: 400px;">
        This app expects quiz data injected via
        <code style="background:#f3f4f6;padding:2px 6px;border-radius:4px;">window.__QUIZ_DATA__</code>
        before the app loads. Open this file through the quiz agent, not directly.
      </p>
    </div>
  `
} else {
  createRoot(root).render(
    <StrictMode>
      <App quizData={quizData} />
    </StrictMode>
  )
}
