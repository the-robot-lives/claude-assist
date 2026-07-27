package com.noizu.timely.di

import android.content.Context
import androidx.room.Room
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import com.noizu.timely.BuildConfig
import com.noizu.timely.data.auth.AuthInterceptor
import com.noizu.timely.data.auth.TokenAuthenticator
import com.noizu.timely.data.auth.TokenStore
import com.noizu.timely.data.local.TimelyDatabase
import com.noizu.timely.data.remote.AuthApi
import com.noizu.timely.data.remote.TimelyApi
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import java.util.concurrent.TimeUnit
import javax.inject.Provider
import javax.inject.Qualifier
import javax.inject.Singleton

/** The Timely base URL, from BuildConfig. Qualified so a bare String is never injectable. */
@Qualifier @Retention(AnnotationRetention.BINARY) annotation class BaseUrl

/** A client with no authenticator, used only to refresh. */
@Qualifier @Retention(AnnotationRetention.BINARY) annotation class RefreshClient

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun json(): Json = Json {
        // The server is allowed to add fields without breaking older installs.
        // Without this, one additive server change bricks sync on every device
        // that has not updated.
        ignoreUnknownKeys = true
        explicitNulls = false
        encodeDefaults = true
        coerceInputValues = true
    }

    @Provides
    @BaseUrl
    fun baseUrl(): String = BuildConfig.TIMELY_BASE_URL

    @Provides
    @Singleton
    @RefreshClient
    fun refreshClient(): OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    @Provides
    @Singleton
    fun tokenAuthenticator(
        tokenStore: TokenStore,
        @RefreshClient refreshClient: Provider<OkHttpClient>,
        @BaseUrl baseUrl: String,
        json: Json,
    ): TokenAuthenticator = TokenAuthenticator(tokenStore, refreshClient, baseUrl, json)

    @Provides
    @Singleton
    fun okHttpClient(
        authInterceptor: AuthInterceptor,
        authenticator: TokenAuthenticator,
    ): OkHttpClient = OkHttpClient.Builder()
        .addInterceptor(authInterceptor)
        .authenticator(authenticator)
        .apply {
            if (BuildConfig.DEBUG) {
                // BODY only in debug. A release build logging bodies would put
                // bearer tokens and a user's time entries in logcat, readable by
                // anything with READ_LOGS on a rooted or dev-enabled device.
                addInterceptor(
                    HttpLoggingInterceptor().apply { level = HttpLoggingInterceptor.Level.BODY },
                )
            }
        }
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(60, TimeUnit.SECONDS)
        .retryOnConnectionFailure(true)
        .build()

    @Provides
    @Singleton
    fun retrofit(client: OkHttpClient, json: Json, @BaseUrl baseUrl: String): Retrofit =
        Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(client)
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()

    @Provides @Singleton fun timelyApi(retrofit: Retrofit): TimelyApi =
        retrofit.create(TimelyApi::class.java)

    @Provides @Singleton fun authApi(retrofit: Retrofit): AuthApi =
        retrofit.create(AuthApi::class.java)

    @Provides
    @Singleton
    fun database(@ApplicationContext context: Context): TimelyDatabase =
        Room.databaseBuilder(context, TimelyDatabase::class.java, TimelyDatabase.NAME)
            // No fallbackToDestructiveMigration. The local store holds the
            // user's unpushed queue; wiping it on a schema bump would silently
            // destroy work that had not reached the server. A missing migration
            // must fail loudly in development instead.
            .build()
}
