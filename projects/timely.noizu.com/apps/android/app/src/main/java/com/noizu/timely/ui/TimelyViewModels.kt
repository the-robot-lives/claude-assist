package com.noizu.timely.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.noizu.timely.data.auth.SessionState
import com.noizu.timely.data.local.ReviewItemEntity
import com.noizu.timely.data.local.SyncStateEntity
import com.noizu.timely.data.local.TimeSpanEntity
import com.noizu.timely.data.local.UserSettingsEntity
import com.noizu.timely.data.local.WorkspacePolicyEntity
import com.noizu.timely.data.repo.AuthRepository
import com.noizu.timely.data.repo.AuthResult
import com.noizu.timely.data.repo.TimelyRepository
import com.noizu.timely.work.SyncScheduler
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import javax.inject.Inject

data class DayUiState(
    val day: LocalDate = LocalDate.now(),
    val spans: List<TimeSpanEntity> = emptyList(),
    val reviewItems: List<ReviewItemEntity> = emptyList(),
    val pendingCount: Int = 0,
    val syncState: SyncStateEntity? = null,
    val session: SessionState = SessionState(),
    val isSyncing: Boolean = false,
) {
    val totalSeconds: Long get() = spans.sumOf { it.elapsedSeconds() }
    val billableSeconds: Long get() = spans.filter { it.isBillable }.sumOf { it.elapsedSeconds() }
    val openSpans: List<TimeSpanEntity> get() = spans.filter { it.end == null }
    val needsReview: List<TimeSpanEntity> get() =
        spans.filter { it.reviewState == "needs_review" || it.reviewState == "disputed" }

    /** Ids with an open, server-raised flag, so a row can render as disputed. */
    val flaggedSpanIds: Set<String> get() =
        reviewItems.filter { it.resolvedAt == null }.map { it.targetId }.toSet()
}

/** Elapsed seconds. An open span is measured to now, which is what the user sees ticking. */
fun TimeSpanEntity.elapsedSeconds(now: Instant = Instant.now()): Long {
    val end = endEpochSeconds ?: now.epochSecond
    return (end - startEpochSeconds).coerceAtLeast(0)
}

fun Long.asHoursLabel(): String {
    val duration = Duration.ofSeconds(this)
    val hours = duration.toHours()
    val minutes = duration.toMinutesPart()
    return if (hours > 0) "${hours}h ${minutes}m" else "${minutes}m"
}

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class TimelyViewModel @Inject constructor(
    private val repository: TimelyRepository,
    private val authRepository: AuthRepository,
    private val syncScheduler: SyncScheduler,
) : ViewModel() {

    private val selectedDay = MutableStateFlow(LocalDate.now())
    private val zone: ZoneId = ZoneId.systemDefault()

    private val daySpans = selectedDay.flatMapLatest { repository.observeDay(it, zone) }

    val state: StateFlow<DayUiState> = combine(
        selectedDay,
        daySpans,
        repository.observeReviewItems(),
        combine(
            repository.observePendingCount(),
            repository.observeSyncState(),
            syncScheduler.observeSyncing(),
        ) { pending, sync, syncing -> Triple(pending, sync, syncing) },
        authRepository.session,
    ) { day, spans, reviewItems, (pending, sync, syncing), session ->
        DayUiState(
            day = day,
            spans = spans,
            reviewItems = reviewItems,
            pendingCount = pending,
            syncState = sync,
            session = session,
            isSyncing = syncing,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), DayUiState())

    fun selectDay(day: LocalDate) { selectedDay.value = day }
    fun previousDay() { selectedDay.value = selectedDay.value.minusDays(1) }
    fun nextDay() { selectedDay.value = selectedDay.value.plusDays(1) }

    /** Pull-to-refresh. Enqueues work; the engine serializes with the periodic run. */
    fun refresh() = syncScheduler.requestImmediateSync()

    // Every one of these writes locally and queues. None of them checks whether
    // the session is valid first -- that is the point.

    fun retitle(spanId: String, title: String) = viewModelScope.launch {
        repository.updateSpan(spanId = spanId, title = title)
    }

    fun toggleBillable(span: TimeSpanEntity) = viewModelScope.launch {
        repository.updateSpan(spanId = span.id, isBillable = !span.isBillable)
    }

    fun reassign(spanId: String, clientName: String, projectName: String, ticketName: String) =
        viewModelScope.launch {
            repository.updateSpan(
                spanId = spanId,
                clientName = clientName,
                projectName = projectName,
                ticketName = ticketName,
            )
        }

    fun split(spanId: String, at: Instant) = viewModelScope.launch {
        repository.splitSpan(spanId, listOf(at))
    }

    fun merge(spanIds: List<String>) = viewModelScope.launch {
        repository.mergeSpans(spanIds)
    }

    fun closeOpenSpan(spanId: String, at: Instant) = viewModelScope.launch {
        repository.updateSpan(spanId = spanId, end = at)
    }

    fun approveDay(spanIds: List<String>) = viewModelScope.launch {
        repository.approveSpans(spanIds)
    }

    /**
     * "Not work."
     *
     * Marks the span disputed rather than deleting it. Evidence-backed tracking
     * means a rejected span still leaves a trace: a deletion would remove the
     * only record that the capture agent ever saw that time, and a later billing
     * dispute has nothing to point at.
     */
    fun markNotWork(spanId: String) = viewModelScope.launch {
        repository.updateSpan(spanId = spanId, reviewState = "disputed")
    }

    /** Confirm inferred time as really having happened. */
    fun confirmSpan(spanId: String) = viewModelScope.launch {
        repository.updateSpan(spanId = spanId, reviewState = "reviewed")
    }

    /**
     * Resolution is always an explicit user choice. Nothing in this view model
     * resolves a duplicate or overlap flag on its own.
     */
    fun resolveReview(itemId: String, resolution: String) = viewModelScope.launch {
        repository.resolveReviewItem(itemId, resolution)
    }

    fun createManualSpan(
        title: String,
        clientName: String,
        projectName: String,
        ticketName: String,
        start: Instant,
        end: Instant?,
        isBillable: Boolean,
        notes: String,
    ) = viewModelScope.launch {
        repository.createManualSpan(
            title = title,
            clientName = clientName,
            projectName = projectName,
            ticketName = ticketName,
            start = start,
            end = end,
            isBillable = isBillable,
            notes = notes,
        )
    }
}

data class ReportsUiState(
    val from: LocalDate = LocalDate.now().minusDays(6),
    val to: LocalDate = LocalDate.now(),
    val spans: List<TimeSpanEntity> = emptyList(),
) {
    data class Group(val label: String, val seconds: Long, val billableSeconds: Long)

    /**
     * Computed from the local mirror, not fetched from `/reports/summary`.
     *
     * The report endpoint exists and is richer, but a companion whose reports go
     * blank on a plane is not a companion. The server's numbers are the ones
     * that bill; these are the ones the user can always see.
     */
    val groups: List<Group>
        get() = spans
            .groupBy { it.projectName.ifBlank { "Unassigned" } }
            .map { (label, rows) ->
                Group(
                    label = label,
                    seconds = rows.sumOf { it.elapsedSeconds() },
                    billableSeconds = rows.filter { it.isBillable }.sumOf { it.elapsedSeconds() },
                )
            }
            .sortedByDescending { it.seconds }

    val totalSeconds: Long get() = spans.sumOf { it.elapsedSeconds() }
    val billableSeconds: Long get() = spans.filter { it.isBillable }.sumOf { it.elapsedSeconds() }
    val unreviewedCount: Int get() = spans.count { it.reviewState == "unreviewed" }
}

@OptIn(ExperimentalCoroutinesApi::class)
@HiltViewModel
class ReportsViewModel @Inject constructor(
    private val repository: TimelyRepository,
) : ViewModel() {

    private val range = MutableStateFlow(LocalDate.now().minusDays(6) to LocalDate.now())
    private val zone: ZoneId = ZoneId.systemDefault()

    val state: StateFlow<ReportsUiState> = range.flatMapLatest { (from, to) ->
        // One query per day in the range, combined. The range is a week or a
        // month, so this is a handful of cheap indexed reads, not an N+1.
        val days = generateSequence(from) { it.plusDays(1) }
            .takeWhile { !it.isAfter(to) }
            .toList()
        combine(days.map { repository.observeDay(it, zone) }) { arrays ->
            ReportsUiState(from = from, to = to, spans = arrays.toList().flatten())
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ReportsUiState())

    fun setRange(from: LocalDate, to: LocalDate) { range.value = from to to }
    fun lastSevenDays() { range.value = LocalDate.now().minusDays(6) to LocalDate.now() }
    fun thisMonth() {
        val now = LocalDate.now()
        range.value = now.withDayOfMonth(1) to now
    }
}

data class SettingsUiState(
    val settings: UserSettingsEntity? = null,
    val policy: WorkspacePolicyEntity? = null,
    val session: SessionState = SessionState(),
    val pendingCount: Int = 0,
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val repository: TimelyRepository,
    private val authRepository: AuthRepository,
) : ViewModel() {

    val state: StateFlow<SettingsUiState> = combine(
        repository.observeSettings(),
        repository.observePolicy(),
        authRepository.session,
        repository.observePendingCount(),
    ) { settings, policy, session, pending ->
        SettingsUiState(settings, policy, session, pending)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), SettingsUiState())

    fun setRetentionDays(days: Int) = viewModelScope.launch {
        repository.updateSettings { it.copy(retentionDays = days) }
    }

    fun setIdleThreshold(minutes: Double) = viewModelScope.launch {
        repository.updateSettings { it.copy(idleThresholdMinutes = minutes) }
    }

    /**
     * The device screenshot gate.
     *
     * This is the *capture agent's* setting, synced from here as a convenience.
     * It does not change anything about this device: Android holds no screenshot
     * bytes regardless of how it is set. The UI says so rather than implying the
     * phone is being switched between two capture modes it never had.
     */
    fun setLocalOnlyScreenshots(localOnly: Boolean) = viewModelScope.launch {
        repository.updateSettings { it.copy(localOnlyScreenshots = localOnly) }
    }

    fun signOut() = authRepository.signOut()
}

data class SignInUiState(
    val email: String = "",
    val password: String = "",
    val busy: Boolean = false,
    val error: String? = null,
    val session: SessionState = SessionState(),
)

@HiltViewModel
class SignInViewModel @Inject constructor(
    private val authRepository: AuthRepository,
) : ViewModel() {

    private val form = MutableStateFlow(SignInUiState())
    val state: StateFlow<SignInUiState> = form.asStateFlow()

    private val sessionState = authRepository.session

    init {
        viewModelScope.launch {
            sessionState.collect { session -> form.value = form.value.copy(session = session) }
        }
    }

    fun onEmail(value: String) { form.value = form.value.copy(email = value, error = null) }
    fun onPassword(value: String) { form.value = form.value.copy(password = value, error = null) }

    fun signIn() = viewModelScope.launch {
        form.value = form.value.copy(busy = true, error = null)
        val result = authRepository.signIn(form.value.email.trim(), form.value.password)
        form.value = form.value.copy(
            busy = false,
            error = when (result) {
                is AuthResult.Success -> null
                is AuthResult.Failed -> result.message
                is AuthResult.Offline ->
                    "Could not reach Timely. You can keep working offline; " +
                        "sign in later to sync."
            },
            password = if (result is AuthResult.Success) "" else form.value.password,
        )
    }

}
