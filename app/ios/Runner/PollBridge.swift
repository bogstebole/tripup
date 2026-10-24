// The dinner poll outside the app, the iOS side. Flutter tells it when the poll opens, when votes come in and when it
// closes (channel "tripup/poll"); it keeps a Live Activity in step and posts a notification with a button per place.
// A vote from either comes back here, updates the activity at once, and goes to Flutter (or waits for it to start).
import ActivityKit
import Flutter
import UserNotifications

final class PollBridge: NSObject {
  static let shared = PollBridge()

  private var channel: FlutterMethodChannel?
  private static let pendingKey = "tripup.poll.pendingVote"
  private static let category = "tripup.poll"

  /// Hooks up to Flutter, and takes votes from the Live Activity's buttons.
  func attach(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "tripup/poll", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result) }
    self.channel = channel
    Task { @MainActor in PollVoteCenter.handle = { place in await PollBridge.shared.vote(place) } }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    // Live Activities need iOS 16.2; before that the poll stays in the app
    guard #available(iOS 16.2, *) else {
      result(call.method == "start" ? false : nil)
      return
    }
    switch call.method {
    case "start":
      Task {
        let posted = await start(args)
        result(posted)
      }
    case "update":
      Task {
        await update(args, ending: false)
        result(nil)
      }
    case "end":
      Task {
        await update(args, ending: true)
        result(nil)
      }
    case "clear":
      Task {
        for activity in Activity<PollActivityAttributes>.activities { await activity.end(nil, dismissalPolicy: .immediate) }
        result(nil)
      }
    case "takeVote":
      let vote = UserDefaults.standard.string(forKey: Self.pendingKey)
      UserDefaults.standard.removeObject(forKey: Self.pendingKey)
      result(vote)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: The Live Activity

  @available(iOS 16.2, *)
  private func state(_ args: [String: Any]) -> PollActivityAttributes.ContentState? {
    guard let s = args["state"] as? [String: Any], let votes = s["votes"] as? [String: Int], let closes = s["closesAt"] as? Double else { return nil }
    return .init(
      votes: votes,
      mine: s["mine"] as? String,
      voted: s["voted"] as? Int ?? 0,
      table: s["table"] as? Int ?? 0,
      closesAt: Date(timeIntervalSince1970: closes / 1000),
      winner: s["winner"] as? String
    )
  }

  @available(iOS 16.2, *)
  private func places(_ args: [String: Any]) -> [PollActivityAttributes.Place] {
    (args["places"] as? [[String: String]] ?? []).compactMap { p in
      guard let id = p["id"], let name = p["name"], let short = p["short"], let sticker = p["sticker"] else { return nil }
      return .init(id: id, name: name, short: short, sticker: sticker)
    }
  }

  /// The poll opened: a Live Activity (if there isn't one), and a notification with a button per place. Returns
  /// whether the notification went out (Flutter then skips its own note).
  @available(iOS 16.2, *)
  private func start(_ args: [String: Any]) async -> Bool {
    guard let state = state(args) else { return false }
    let places = places(args)
    let question = args["question"] as? String ?? ""
    let askedBy = args["askedBy"] as? String ?? ""
    if Activity<PollActivityAttributes>.activities.isEmpty, ActivityAuthorizationInfo().areActivitiesEnabled {
      let attributes = PollActivityAttributes(question: question, askedBy: askedBy, places: places)
      _ = try? Activity.request(attributes: attributes, content: .init(state: state, staleDate: state.closesAt), pushType: nil)
    }
    // The notification only for a poll that has just opened (not one the demo jumped into the middle of)
    guard args["notify"] as? Bool ?? true else { return false }
    return await notify(question: question, askedBy: askedBy, places: places, closesAt: state.closesAt)
  }

  /// New votes (or the poll closed): the activity follows. Once closed it stays a while, then goes.
  @available(iOS 16.2, *)
  private func update(_ args: [String: Any], ending: Bool) async {
    guard let state = state(args) else { return }
    for activity in Activity<PollActivityAttributes>.activities {
      let content = ActivityContent(state: state, staleDate: ending ? nil : state.closesAt)
      if ending {
        // A decided poll stays a while to show the winner; one the demo jumped away from goes at once
        await activity.end(content, dismissalPolicy: state.winner == nil ? .immediate : .after(.now.addingTimeInterval(15 * 60)))
      } else {
        await activity.update(content)
      }
    }
  }

  /// A vote from the activity or the notification: shown on the activity at once, then handed to Flutter (or kept
  /// for when it starts).
  @MainActor
  func vote(_ place: String) async {
    UserDefaults.standard.set(place, forKey: Self.pendingKey)
    if #available(iOS 16.2, *) {
      for activity in Activity<PollActivityAttributes>.activities {
        var s = activity.content.state
        guard s.winner == nil, s.mine != place else { continue }
        if let old = s.mine {
          s.votes[old] = max(0, (s.votes[old] ?? 1) - 1)
        } else {
          s.voted += 1
        }
        s.votes[place, default: 0] += 1
        s.mine = place
        await activity.update(ActivityContent(state: s, staleDate: s.closesAt))
      }
    }
    if let channel {
      UserDefaults.standard.removeObject(forKey: Self.pendingKey)
      channel.invokeMethod("voted", arguments: place)
    }
  }

  // MARK: The notification

  @available(iOS 16.2, *)
  private func notify(question: String, askedBy: String, places: [PollActivityAttributes.Place], closesAt: Date) async -> Bool {
    let center = UNUserNotificationCenter.current()
    var settings = await center.notificationSettings()
    if settings.authorizationStatus == .notDetermined {
      _ = try? await center.requestAuthorization(options: [.alert, .sound])
      settings = await center.notificationSettings()
    }
    guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return false }
    // One button per place; voting doesn't open the app
    let actions = places.map { UNNotificationAction(identifier: "vote.\($0.id)", title: $0.short, options: []) }
    center.setNotificationCategories([UNNotificationCategory(identifier: Self.category, actions: actions, intentIdentifiers: [])])
    let content = UNMutableNotificationContent()
    content.title = "\(askedBy) started a poll"
    // In minutes from now (the demo's clock isn't the phone's)
    let minutes = max(1, Int((closesAt.timeIntervalSinceNow / 60).rounded(.up)))
    content.body = "\(question) Closes in \(minutes) min. Hold to vote."
    content.categoryIdentifier = Self.category
    content.sound = .default
    do {
      try await center.add(UNNotificationRequest(identifier: "tripup.poll.opened", content: content, trigger: nil))
      return true
    } catch {
      return false
    }
  }

  /// A button on the notification: vote, without opening the app.
  func handleNotification(_ response: UNNotificationResponse) async -> Bool {
    let id = response.actionIdentifier
    guard id.hasPrefix("vote.") else { return false }
    await vote(String(id.dropFirst("vote.".count)))
    return true
  }
}
