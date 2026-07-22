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

object TimelyFixtures {
    val summary = TimelySummary(
        reviewedHours = 6.4,
        billableHours = 5.75,
        confidence = 87,
        unresolvedPrompts = 3
    )

    val intervals = listOf(
        TimelyInterval("08:45", "10:05", "Timely Alpha", "Timeline keyboard prototype", "Captured", 92),
        TimelyInterval("10:05", "10:42", "Incident Review", "Deploy monitor and client update", "Overlap", 81),
        TimelyInterval("11:18", "11:52", "Idle", "Away from keyboard", "Idle", 66),
        TimelyInterval("12:20", "14:05", "Incident Review", "Root cause notes", "Manual", 88)
    )

    val policy = TimelyPolicy(
        screenshotIntervalMinutes = 5,
        localOnlyScreenshots = true,
        retentionDays = 21,
        excludedApps = listOf("1Password", "Messages")
    )
}

