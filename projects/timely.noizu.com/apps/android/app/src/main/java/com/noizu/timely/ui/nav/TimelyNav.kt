package com.noizu.timely.ui.nav

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Assessment
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material.icons.filled.Today
import androidx.compose.material.icons.filled.ViewTimeline
import androidx.compose.material.icons.automirrored.filled.HelpOutline
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.noizu.timely.ui.ReportsViewModel
import com.noizu.timely.ui.SettingsViewModel
import com.noizu.timely.ui.SignInViewModel
import com.noizu.timely.ui.TimelyViewModel
import com.noizu.timely.ui.screens.IdleReviewScreen
import com.noizu.timely.ui.screens.ManualEntryScreen
import com.noizu.timely.ui.screens.PrivacySettingsScreen
import com.noizu.timely.ui.screens.ReportsScreen
import com.noizu.timely.ui.screens.SignInScreen
import com.noizu.timely.ui.screens.TimelineScreen
import com.noizu.timely.ui.screens.TodayScreen
import java.time.Instant

enum class TimelyDestination(
    val route: String,
    val label: String,
    val icon: ImageVector,
) {
    TODAY("today", "Today", Icons.Filled.Today),
    TIMELINE("timeline", "Timeline", Icons.Filled.ViewTimeline),
    REVIEW("review", "Review", Icons.AutoMirrored.Filled.HelpOutline),
    REPORTS("reports", "Reports", Icons.Filled.Assessment),
    PRIVACY("privacy", "Privacy", Icons.Filled.Shield),
}

private const val ROUTE_MANUAL_ENTRY = "manual-entry"
private const val ROUTE_SIGN_IN = "sign-in"

/**
 * The shell.
 *
 * Sign-in is a destination inside the graph rather than a gate in front of it.
 * That is the structural expression of "never gate local reads or writes on auth
 * freshness": there is no arrangement of app state that can strand a user on a
 * login screen with their timeline behind it.
 */
@Composable
fun TimelyApp(
    onLaunchOidc: () -> Unit,
    ssoBanner: kotlinx.coroutines.flow.StateFlow<com.noizu.timely.MainActivity.SsoBanner?>,
    onDismissSsoBanner: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val navController = rememberNavController()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = backStackEntry?.destination

    val timelyViewModel: TimelyViewModel = hiltViewModel()
    val dayState by timelyViewModel.state.collectAsStateWithLifecycle()

    val showBottomBar = currentDestination?.route !in setOf(ROUTE_SIGN_IN, ROUTE_MANUAL_ENTRY)

    Scaffold(
        modifier = modifier,
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    for (destination in TimelyDestination.entries) {
                        val selected = currentDestination?.hierarchy
                            ?.any { it.route == destination.route } == true
                        val badge = when (destination) {
                            TimelyDestination.REVIEW ->
                                dayState.openSpans.size + dayState.needsReview.size
                            else -> 0
                        }
                        NavigationBarItem(
                            selected = selected,
                            onClick = {
                                navController.navigate(destination.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            icon = {
                                BadgedBox(
                                    badge = {
                                        if (badge > 0) Badge { Text(badge.toString()) }
                                    },
                                ) {
                                    Icon(destination.icon, contentDescription = destination.label)
                                }
                            },
                            label = { Text(destination.label) },
                        )
                    }
                }
            }
        },
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = TimelyDestination.TODAY.route,
            modifier = Modifier.padding(padding),
        ) {
            composable(TimelyDestination.TODAY.route) {
                TodayScreen(
                    state = dayState,
                    onRefresh = timelyViewModel::refresh,
                    onOpenSpan = { navController.navigate(TimelyDestination.TIMELINE.route) },
                    onCloseOpenSpan = { id, at -> timelyViewModel.closeOpenSpan(id, at) },
                    onResolveReview = timelyViewModel::resolveReview,
                    onApproveDay = { timelyViewModel.approveDay(dayState.spans.map { it.id }) },
                    onAddManual = { navController.navigate(ROUTE_MANUAL_ENTRY) },
                )
            }

            composable(TimelyDestination.TIMELINE.route) {
                TimelineScreen(
                    state = dayState,
                    onPreviousDay = timelyViewModel::previousDay,
                    onNextDay = timelyViewModel::nextDay,
                    onRetitle = timelyViewModel::retitle,
                    onToggleBillable = timelyViewModel::toggleBillable,
                    onReassign = timelyViewModel::reassign,
                    onSplit = timelyViewModel::split,
                    onMerge = timelyViewModel::merge,
                )
            }

            composable(TimelyDestination.REVIEW.route) {
                IdleReviewScreen(
                    state = dayState,
                    onKeep = { span -> timelyViewModel.confirmSpan(span.id) },
                    onDiscard = { span -> timelyViewModel.markNotWork(span.id) },
                    onCloseNow = { span ->
                        timelyViewModel.closeOpenSpan(span.id, Instant.now())
                    },
                    onOpenSpan = { navController.navigate(TimelyDestination.TIMELINE.route) },
                )
            }

            composable(TimelyDestination.REPORTS.route) {
                val reportsViewModel: ReportsViewModel = hiltViewModel()
                val reportState by reportsViewModel.state.collectAsStateWithLifecycle()
                ReportsScreen(
                    state = reportState,
                    onLastSevenDays = reportsViewModel::lastSevenDays,
                    onThisMonth = reportsViewModel::thisMonth,
                )
            }

            composable(TimelyDestination.PRIVACY.route) {
                val settingsViewModel: SettingsViewModel = hiltViewModel()
                val settingsState by settingsViewModel.state.collectAsStateWithLifecycle()
                PrivacySettingsScreen(
                    state = settingsState,
                    onSetLocalOnlyScreenshots = settingsViewModel::setLocalOnlyScreenshots,
                    onSetRetentionDays = settingsViewModel::setRetentionDays,
                    onSignOut = settingsViewModel::signOut,
                    onSignIn = { navController.navigate(ROUTE_SIGN_IN) },
                )
            }

            composable(ROUTE_MANUAL_ENTRY) {
                ManualEntryScreen(
                    day = dayState.day,
                    onSave = { title, client, project, ticket, start, end, billable, notes ->
                        timelyViewModel.createManualSpan(
                            title = title,
                            clientName = client,
                            projectName = project,
                            ticketName = ticket,
                            start = start,
                            end = end,
                            isBillable = billable,
                            notes = notes,
                        )
                        navController.popBackStack()
                    },
                    onCancel = { navController.popBackStack() },
                )
            }

            composable(ROUTE_SIGN_IN) {
                val signInViewModel: SignInViewModel = hiltViewModel()
                val signInState by signInViewModel.state.collectAsStateWithLifecycle()
                val banner by ssoBanner.collectAsStateWithLifecycle()
                SignInScreen(
                    state = signInState,
                    ssoBanner = banner,
                    onDismissSsoBanner = onDismissSsoBanner,
                    onEmail = signInViewModel::onEmail,
                    onPassword = signInViewModel::onPassword,
                    onSignIn = signInViewModel::signIn,
                    onOidcSignIn = onLaunchOidc,
                    onContinueOffline = { navController.popBackStack() },
                )
            }
        }
    }
}
