package com.noizu.timely.work

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.noizu.timely.data.sync.SyncEngine
import com.noizu.timely.data.sync.SyncOutcome
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Periodic background sync.
 *
 * A companion app syncing in the background is the *only* background work this
 * app does. There is no capture service, no always-on timer, and no
 * foreground-service notification, because Android does not capture anything
 * (apps/README.md).
 */
@HiltWorker
class SyncWorker @AssistedInject constructor(
    @Assisted appContext: Context,
    @Assisted params: WorkerParameters,
    private val syncEngine: SyncEngine,
) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result = when (val outcome = syncEngine.sync()) {
        is SyncOutcome.Success -> Result.success()

        // Not signed in, or the token is stale and refresh did not fix it.
        // SUCCESS, not failure or retry: there is nothing wrong and nothing to
        // retry. Returning retry here would burn the backoff schedule against a
        // condition only the user can clear, and would keep waking the device
        // all night for a signed-out app. Local reads and writes are unaffected.
        SyncOutcome.AuthRequired, SyncOutcome.Idle -> Result.success()

        // The device slept past the tombstone horizon. Retrying the incremental
        // pull cannot fix it; a full resync has to be started deliberately.
        SyncOutcome.ResyncRequired -> Result.success()

        is SyncOutcome.Retry ->
            if (runAttemptCount >= MAX_ATTEMPTS) {
                // Stop burning battery. The queue is intact and the next
                // periodic run picks it up.
                Result.success()
            } else {
                Result.retry()
            }
    }

    companion object {
        const val PERIODIC_NAME = "timely-periodic-sync"
        const val ONESHOT_NAME = "timely-manual-sync"
        private const val MAX_ATTEMPTS = 6
    }
}

/**
 * Scheduling policy, kept in one place so the periodic job and the manual
 * refresh cannot drift apart.
 */
@Singleton
class SyncScheduler @Inject constructor(
    @ApplicationContext private val context: Context,
) {

    private val workManager: WorkManager get() = WorkManager.getInstance(context)

    /**
     * 15 minutes is not a choice -- it is WorkManager's floor for periodic work.
     * Asking for less silently gets 15 anyway, so it is stated explicitly rather
     * than written as a smaller number that quietly does not mean what it says.
     */
    fun ensurePeriodicSync() {
        val request = PeriodicWorkRequestBuilder<SyncWorker>(15, TimeUnit.MINUTES)
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build(),
            )
            // Full-jitter-ish: WorkManager's EXPONENTIAL policy already spreads
            // retries, and its floor is 10s.
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
            .addTag(TAG)
            .build()

        // KEEP, not UPDATE: every cold start would otherwise reset the period
        // and a device that is opened often would never actually reach a
        // scheduled run.
        workManager.enqueueUniquePeriodicWork(
            SyncWorker.PERIODIC_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }

    /**
     * Pull-to-refresh.
     *
     * REPLACE rather than KEEP so a user who pulls again after a failure gets a
     * fresh attempt instead of being told one is already queued. The sync engine
     * holds a mutex, so this can never actually run two batches at once.
     */
    fun requestImmediateSync() {
        val request = OneTimeWorkRequestBuilder<SyncWorker>()
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build(),
            )
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 10, TimeUnit.SECONDS)
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .addTag(TAG)
            .build()

        workManager.enqueueUniqueWork(
            SyncWorker.ONESHOT_NAME,
            ExistingWorkPolicy.REPLACE,
            request,
        )
    }

    /** True while any sync work is enqueued or running, for the refresh spinner. */
    fun observeSyncing(): Flow<Boolean> =
        workManager.getWorkInfosByTagFlow(TAG).map { infos ->
            infos.any { it.state == WorkInfo.State.RUNNING || it.state == WorkInfo.State.ENQUEUED }
        }

    fun cancelAll() {
        workManager.cancelAllWorkByTag(TAG)
    }

    private companion object {
        const val TAG = "timely-sync"
    }
}
