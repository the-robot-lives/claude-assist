import SwiftUI

struct SettingsView: View {
    @Binding var policy: CapturePolicy

    var body: some View {
        Form {
            Stepper("Screenshot interval: \(policy.screenshotIntervalMinutes) minutes", value: $policy.screenshotIntervalMinutes, in: 1...30)
            Toggle("Store screenshots locally only", isOn: $policy.localOnlyScreenshots)
            Stepper("Retention: \(policy.retentionDays) days", value: $policy.retentionDays, in: 1...90)

            Section("Excluded apps") {
                ForEach(policy.excludedApps, id: \.self) { app in
                    Text(app)
                }
            }
        }
        .padding()
        .frame(width: 520)
    }
}

