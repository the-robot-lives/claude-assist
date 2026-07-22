# Timely Android App

Kotlin and Jetpack Compose scaffold for Timely's mobile companion.

Current capabilities:

- Mobile-first summary screen for reviewed hours, billable hours, confidence, and unresolved prompts.
- Timeline interval list using shared Timely domain concepts.
- Pause/resume UI state for companion review.
- Privacy policy card for screenshot interval, local-only mode, retention, and app exclusions.

Expected build command when Android Gradle tooling is available:

```bash
gradle :app:assembleDebug
```

This scaffold does not include a Gradle wrapper or generated launcher icons yet. Add those through Android Studio or the repository's mobile build tooling before CI.

