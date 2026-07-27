package com.noizu.timely.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.noizu.timely.ui.SignInUiState
import com.noizu.timely.ui.theme.Radii
import com.noizu.timely.ui.theme.Spacing

/**
 * Sign-in.
 *
 * Reachable, dismissable, and never mandatory. "Continue offline" is a
 * first-class action rather than a grudging escape hatch: a user who cannot
 * reach the server still has a full local timeline to read and edit, and
 * blocking them at a login wall would throw that away for no reason.
 */
@Composable
fun SignInScreen(
    state: SignInUiState,
    ssoBanner: com.noizu.timely.MainActivity.SsoBanner? = null,
    onDismissSsoBanner: () -> Unit = {},
    onEmail: (String) -> Unit,
    onPassword: (String) -> Unit,
    onSignIn: () -> Unit,
    onOidcSignIn: () -> Unit,
    onContinueOffline: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(Spacing.page),
        verticalArrangement = Arrangement.spacedBy(Spacing.compact),
    ) {
        Text("Timely", style = MaterialTheme.typography.headlineLarge)
        Text(
            if (state.session.reauthRequired) {
                "Your session expired. Your timeline and any unsynced changes are " +
                    "safe on this device - sign in to resume syncing."
            } else {
                "Sign in to sync with your workspace."
            },
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )

        // The SSO outcome, said in a sentence a person can act on rather than
        // as a raw code. `isRetryable` and `suggestsPasswordFallback` drive
        // which affordance is offered: telling someone whose account was never
        // provisioned to "try again" invites an identical failure, so that case
        // points at the password form instead.
        ssoBanner?.let { banner ->
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        MaterialTheme.colorScheme.error.copy(alpha = 0.08f),
                        RoundedCornerShape(Radii.card),
                    )
                    .padding(Spacing.card),
                verticalArrangement = Arrangement.spacedBy(Spacing.tight),
            ) {
                Text(banner.title, style = MaterialTheme.typography.titleMedium)
                Text(
                    banner.detail,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Row(horizontalArrangement = Arrangement.spacedBy(Spacing.base)) {
                    if (banner.isRetryable) {
                        TextButton(onClick = { onDismissSsoBanner(); onOidcSignIn() }) {
                            Text("Try again")
                        }
                    }
                    if (banner.suggestsPasswordFallback) {
                        Text(
                            "Or sign in with your email and password below.",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(top = Spacing.base),
                        )
                    }
                }
            }
        }

        OutlinedTextField(
            value = state.email,
            onValueChange = onEmail,
            label = { Text("Email") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            enabled = !state.busy,
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Email,
                imeAction = ImeAction.Next,
            ),
        )
        OutlinedTextField(
            value = state.password,
            onValueChange = onPassword,
            label = { Text("Password") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            enabled = !state.busy,
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Done,
            ),
        )

        state.error?.let {
            Text(it, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.error)
        }

        Button(
            onClick = onSignIn,
            modifier = Modifier.fillMaxWidth(),
            enabled = !state.busy && state.email.isNotBlank() && state.password.isNotBlank(),
        ) {
            if (state.busy) {
                CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp)
            } else {
                Text("Sign in")
            }
        }

        HorizontalDivider(Modifier.padding(vertical = Spacing.base))

        OutlinedButton(
            onClick = onOidcSignIn,
            modifier = Modifier.fillMaxWidth(),
            enabled = !state.busy,
        ) { Text("Sign in with Noizu SSO") }

        TextButton(onClick = onContinueOffline, modifier = Modifier.fillMaxWidth()) {
            Text("Continue offline")
        }
        Text(
            "You can read and edit your timeline without signing in. Changes queue " +
                "on this device and sync once you are signed in again.",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}
