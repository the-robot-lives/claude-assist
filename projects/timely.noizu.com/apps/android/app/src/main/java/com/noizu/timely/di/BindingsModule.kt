package com.noizu.timely.di

import com.noizu.timely.data.auth.SessionStore
import com.noizu.timely.data.auth.TokenStore
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class BindingsModule {

    /**
     * There is exactly one [TokenStore], and [SessionStore] is a view onto it.
     * Binding rather than providing keeps that true: injecting the interface and
     * injecting the class both reach the same encrypted preferences file, so a
     * token saved through one is visible through the other.
     */
    @Binds
    @Singleton
    abstract fun sessionStore(impl: TokenStore): SessionStore
}
