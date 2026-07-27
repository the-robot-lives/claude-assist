package com.noizu.timely

import android.app.Application
import androidx.hilt.work.HiltWorkerFactory
import androidx.work.Configuration
import com.noizu.timely.work.SyncScheduler
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject

@HiltAndroidApp
class TimelyApplication : Application(), Configuration.Provider {

    @Inject lateinit var workerFactory: HiltWorkerFactory
    @Inject lateinit var syncScheduler: SyncScheduler

    /**
     * WorkManager's own initializer is removed in the manifest so this is the
     * only configuration that runs. With both in play, WorkManager initializes
     * on first content-provider pass with the default factory, cannot construct
     * an `@HiltWorker`, and the sync worker fails at runtime only -- never at
     * build time, and never in a unit test.
     */
    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setWorkerFactory(workerFactory)
            .build()

    override fun onCreate() {
        super.onCreate()
        // Idempotent: KEEP policy, so this does not reset the period or drop an
        // already-scheduled run on every cold start.
        syncScheduler.ensurePeriodicSync()
    }
}
