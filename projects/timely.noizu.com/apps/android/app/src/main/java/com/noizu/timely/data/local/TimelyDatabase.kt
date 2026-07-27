package com.noizu.timely.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [
        ClientEntity::class,
        ProjectEntity::class,
        TicketEntity::class,
        TimeSpanEntity::class,
        ScreenshotEntity::class,
        VisionAnalysisEntity::class,
        CensoredScreenshotEntity::class,
        DeviceEntity::class,
        UserSettingsEntity::class,
        WorkspacePolicyEntity::class,
        PendingMutationEntity::class,
        SyncStateEntity::class,
        ReviewItemEntity::class,
    ],
    version = 1,
    exportSchema = true,
)
abstract class TimelyDatabase : RoomDatabase() {
    abstract fun clients(): ClientDao
    abstract fun projects(): ProjectDao
    abstract fun tickets(): TicketDao
    abstract fun timeSpans(): TimeSpanDao
    abstract fun screenshots(): ScreenshotDao
    abstract fun visionAnalyses(): VisionAnalysisDao
    abstract fun censoredScreenshots(): CensoredScreenshotDao
    abstract fun devices(): DeviceDao
    abstract fun settings(): SettingsDao
    abstract fun pendingMutations(): PendingMutationDao
    abstract fun syncState(): SyncStateDao
    abstract fun reviewItems(): ReviewItemDao

    companion object {
        const val NAME = "timely.db"
    }
}
