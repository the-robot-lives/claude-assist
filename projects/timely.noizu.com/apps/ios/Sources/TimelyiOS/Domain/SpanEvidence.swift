import Foundation
import TimelyKit

/// Everything this device knows about what backs a span.
///
/// A companion almost never holds image bytes — `Screenshot.isMetadataOnly` is
/// the normal case, not a degraded one — so the recall surface here is the
/// metadata plus `VisionAnalysis.recallSummary`. Nothing in this type reaches
/// for pixels, and nothing in the app renders `VisionAnalysis.rawResponse`,
/// which is image-equivalent and behind the same gate as the bytes.
struct SpanEvidence: Sendable, Hashable {
    var screenshots: [Screenshot] = []
    var analyses: [VisionAnalysis] = []
    var censored: [CensoredScreenshot] = []

    static let none = SpanEvidence()

    var isEmpty: Bool {
        screenshots.isEmpty && analyses.isEmpty && censored.isEmpty
    }

    /// The best-supported analysis, by model confidence.
    var strongestAnalysis: VisionAnalysis? {
        analyses.max { $0.confidence < $1.confidence }
    }

    var peakConfidence: Double {
        strongestAnalysis?.confidence ?? 0
    }

    /// True when any evidence for this span touched something the user or the
    /// model marked private. Censorship counts even without an analysis: the
    /// row exists precisely because someone asked for those pixels to be gone.
    var containsPrivateMaterial: Bool {
        if !censored.isEmpty { return true }
        return analyses.contains { $0.privacySensitive || $0.privacyCategory.isSensitive }
    }

    /// Analyses that are safe to render. `rawResponse` is never surfaced.
    var recallLines: [String] {
        analyses
            .sorted { $0.analyzedAt > $1.analyzedAt }
            .map(\.recallSummary)
            .filter { !$0.isEmpty }
    }
}
