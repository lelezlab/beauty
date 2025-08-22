import Foundation
import SwiftUI

final class ResultsStore: ObservableObject {
    @Published var lastMetrics: AestheticsMetrics?
    @Published var lastSuggestions: [Suggestion] = []

    func update(metrics: AestheticsMetrics?, suggestions: [Suggestion]) {
        self.lastMetrics = metrics
        self.lastSuggestions = suggestions
    }
}


