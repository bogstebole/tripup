// The dinner poll as a Live Activity: shared by the app (which starts and updates it) and the widget extension (which
// draws it on the lock screen and in the Dynamic Island).
import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct PollActivityAttributes: ActivityAttributes {
  /// A place to vote for: its id, its full and short name, and its sticker (an image in the extension's assets).
  struct Place: Codable, Hashable {
    let id: String
    let name: String
    let short: String
    let sticker: String
  }

  /// What changes while the poll runs.
  struct ContentState: Codable, Hashable {
    /// Votes per place id.
    var votes: [String: Int]

    /// The place I voted for, if I have.
    var mine: String?

    /// How many at the table have voted, and how many there are.
    var voted: Int
    var table: Int

    /// When it closes (real time: the activity's countdown runs on its own).
    var closesAt: Date

    /// Once it has closed: the place that won.
    var winner: String?
  }

  let question: String
  let askedBy: String
  let places: [Place]
}
