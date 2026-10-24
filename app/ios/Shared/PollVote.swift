// Voting from outside the app: the Live Activity's buttons (this intent) and the notification's actions both end up
// in [PollVoteCenter.handle], which the app sets at launch. The intent runs in the app's process, never the widget's.
import AppIntents
import Foundation

enum PollVoteCenter {
  /// What a vote from outside the app does: set by the app at launch (nil in the widget extension).
  @MainActor static var handle: ((String) async -> Void)?
}

@available(iOS 17.0, *)
struct PollVoteIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Vote for a place"
  static var isDiscoverable: Bool { false }

  @Parameter(title: "Place")
  var place: String

  init() {}

  init(place: String) {
    self.place = place
  }

  func perform() async throws -> some IntentResult {
    await PollVoteCenter.handle?(place)
    return .result()
  }
}
