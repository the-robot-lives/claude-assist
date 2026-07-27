import Foundation
import TimelyKit

/// Small adapters that let the existing SwiftUI layer bind to TimelyKit's
/// models without being rewritten.
///
/// Deliberately thin. Anything with real behaviour belongs in the package,
/// where it is shared with the companions and covered by the package's tests —
/// this file is only for shapes SwiftUI wants that the wire model has no reason
/// to carry.

extension TimeSpan {
    /// Elapsed time, measured to *now* for a span that is still running.
    ///
    /// The shared model spells this `duration(now:)` so a report can compute a
    /// rollup against a fixed instant rather than a moving one. The UI always
    /// wants "as of this moment", and it reads better at the call site as a
    /// property, which is what the pre-retrofit model had.
    var duration: TimeInterval { duration(now: Date()) }
}

extension SpanSource: @retroactive Identifiable {
    /// `Picker` needs a stable identity per case. The shared enum is
    /// `CaseIterable` and `Hashable` already; this is only the `Identifiable`
    /// conformance SwiftUI asks for by name.
    public var id: String { rawValue }
}
