package com.noizu.timely.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.noizu.timely.data.privacy.ScreenshotGate
import com.noizu.timely.ui.SettingsUiState
import com.noizu.timely.ui.components.SectionHeader
import com.noizu.timely.ui.components.SyncStatusBar
import com.noizu.timely.ui.theme.Spacing

/**
 * Privacy and settings.
 *
 * The framing is deliberate: this screen distinguishes facts about *this
 * device* from settings that belong to the *capture agent*. Presenting the
 * agent's screenshot policy as if it were a phone toggle would imply the phone
 * captures, which it does not -- and a privacy screen that misleads about what
 * is captured is worse than no privacy screen.
 */
@Composable
fun PrivacySettingsScreen(
    state: SettingsUiState,
    onSetLocalOnlyScreenshots: (Boolean) -> Unit,
    onSetRetentionDays: (Int) -> Unit,
    onSignOut: () -> Unit,
    onSignIn: () -> Unit,
    modifier: Modifier = Modifier,
) {
    LazyColumn(
        modifier = modifier.fillMaxSize().padding(horizontal = Spacing.card),
        verticalArrangement = Arrangement.spacedBy(Spacing.compact),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(vertical = Spacing.card),
    ) {
        item {
            SyncStatusBar(
                pendingCount = state.pendingCount,
                reauthRequired = state.session.reauthRequired || !state.session.isSignedIn,
                isSyncing = false,
                lastError = null,
            )
        }

        item {
            SectionHeader(
                "This device",
                "What the Android app can and cannot do.",
            )
        }
        item {
            FactRow(
                label = "Screen capture",
                value = "Never",
                detail = "This app holds no screen-capture permission and has no code " +
                    "path that uploads image data. Screenshots are captured and stored " +
                    "by the desktop agent only.",
            )
        }
        item {
            FactRow(
                label = "Capture agent",
                value = if (ScreenshotGate.IS_CAPTURE_AGENT) "Yes" else "No - companion only",
                detail = "This device reviews and edits time. It does not record it.",
            )
        }
        item {
            FactRow(
                label = "Local storage",
                value = "Encrypted credentials",
                detail = "Sign-in tokens are held in the Android Keystore. Your timeline " +
                    "is stored on this device so it stays readable and editable offline, " +
                    "and is excluded from cloud backup.",
            )
        }

        item { HorizontalDivider() }

        item {
            SectionHeader(
                "Capture policy",
                "These belong to your workspace and the desktop agent. Changing them " +
                    "here syncs the change to that agent; it does not change this phone.",
            )
        }

        val settings = state.settings
        if (settings == null) {
            item {
                Text(
                    "Capture settings will appear after the first sync.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        } else {
            item {
                ToggleRow(
                    label = "Keep screenshots local-only",
                    detail = "When on, the desktop agent never uploads screenshot images " +
                        "to the server; only the fact that a screenshot exists is synced.",
                    checked = settings.localOnlyScreenshots,
                    // The workspace policy can forbid uploads outright. When it
                    // does, the toggle is shown as locked rather than hidden --
                    // a user should be able to see that the stricter setting is
                    // in force and is not theirs to relax.
                    enabled = state.policy?.screenshotUploadAllowed != false,
                    onCheckedChange = onSetLocalOnlyScreenshots,
                )
            }
            if (state.policy?.screenshotUploadAllowed == false) {
                item {
                    Text(
                        "Your workspace policy forbids screenshot upload, so this cannot " +
                            "be turned off.",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            item {
                FactRow(
                    label = "Screenshot interval",
                    value = "${settings.screenshotIntervalMinutes} min",
                    detail = "How often the desktop agent captures.",
                )
            }
            item {
                FactRow(
                    label = "Retention",
                    value = if (settings.retentionDays <= 0) {
                        "Forever"
                    } else {
                        "${settings.retentionDays} days"
                    },
                    detail = "How long captured evidence is kept.",
                )
            }
            item {
                FactRow(
                    label = "Idle threshold",
                    value = "${settings.idleThresholdMinutes} min",
                    detail = "Inactivity longer than this becomes an idle gap to resolve.",
                )
            }
            item {
                FactRow(
                    label = "Vision analysis",
                    value = if (settings.visionAnalysisEnabled) "Enabled" else "Disabled",
                    detail = if (settings.visionAnalysisEnabled) {
                        "A model reads screenshots to suggest projects. Suggestions are " +
                            "labelled Inferred until you confirm them."
                    } else {
                        "No model reads your screenshots."
                    },
                )
            }
        }

        item { HorizontalDivider() }

        item { SectionHeader("Account", state.session.email ?: "Not signed in") }
        item {
            if (state.session.isSignedIn && !state.session.reauthRequired) {
                Column(verticalArrangement = Arrangement.spacedBy(Spacing.base)) {
                    OutlinedButton(onClick = onSignOut, modifier = Modifier.fillMaxWidth()) {
                        Text("Sign out")
                    }
                    Text(
                        "Signing out keeps your local timeline and any changes that have " +
                            "not synced yet.",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            } else {
                OutlinedButton(onClick = onSignIn, modifier = Modifier.fillMaxWidth()) {
                    Text("Sign in")
                }
            }
        }
    }
}

@Composable
private fun FactRow(label: String, value: String, detail: String) {
    Column(verticalArrangement = Arrangement.spacedBy(Spacing.tight)) {
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(label, style = MaterialTheme.typography.bodyLarge)
            Text(value, style = MaterialTheme.typography.labelLarge)
        }
        Text(
            detail,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun ToggleRow(
    label: String,
    detail: String,
    checked: Boolean,
    enabled: Boolean,
    onCheckedChange: (Boolean) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(Spacing.tight)) {
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(label, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
            Switch(checked = checked, onCheckedChange = onCheckedChange, enabled = enabled)
        }
        Text(
            detail,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}
