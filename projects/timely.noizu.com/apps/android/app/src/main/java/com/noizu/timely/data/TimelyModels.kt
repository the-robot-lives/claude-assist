package com.noizu.timely.data

data class TimelySummary(
    val reviewedHours: Double,
    val billableHours: Double,
    val confidence: Int,
    val unresolvedPrompts: Int
)

data class TimelyInterval(
    val start: String,
    val end: String,
    val project: String,
    val task: String,
    val state: String,
    val confidence: Int
)

data class TimelyPolicy(
    val screenshotIntervalMinutes: Int,
    val localOnlyScreenshots: Boolean,
    val retentionDays: Int,
    val excludedApps: List<String>
)

object TimelyState {
    val summary = TimelySummary(
        reviewedHours = 0.0,
        billableHours = 0.0,
        confidence = 0,
        unresolvedPrompts = 0
    )

    val intervals = emptyList<TimelyInterval>()

    val policy = TimelyPolicy(
        screenshotIntervalMinutes = 0,
        localOnlyScreenshots = false,
        retentionDays = 0,
        excludedApps = emptyList()
    )
}
