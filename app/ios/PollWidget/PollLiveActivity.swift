// The dinner poll on the lock screen and in the Dynamic Island. It's the app's poll card (Bogdan's design, Figma
// 82:3) made to fit the little room a Live Activity has: the live line and countdown, the question, then the three
// places side by side as small cards, each with its sticker, name, a bar of its votes, and the vote (the whole card
// is the button). It follows the system's light or dark look on the lock screen; the Island is always dark.
import ActivityKit
import SwiftUI
import WidgetKit

// Its own measurements: used only here, so they're not tokens.
private let pollActivityMark: CGFloat = 20
private let pollActivityBar: CGFloat = 4
private let pollActivityTimer: CGFloat = 48
private let pollMarkRing: CGFloat = 2

struct PollLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: PollActivityAttributes.self) { context in
      PollLockScreen(context: context)
        .widgetURL(pollURL)   // the activity itself (not a vote) opens the poll in the app
    } dynamicIsland: { context in
      let tok = TokColors.dark
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          LiveLine(state: context.state, tok: tok, short: true).padding(.leading, TokSpace.xs)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Countdown(state: context.state, tok: tok).padding(.trailing, TokSpace.xs)
        }
        DynamicIslandExpandedRegion(.bottom) {
          PlaceCards(context: context, tok: tok).padding(.top, TokSpace.xs)
        }
      } compactLeading: {
        HStack(spacing: TokSpace.x2xs) {
          LiveDot(tok: tok)
          Text(context.state.winner == nil ? "Poll" : "Dinner").font(TokText.labelMd.weight(.semibold)).foregroundStyle(tok.textDefault)
        }
      } compactTrailing: {
        if let winner = context.attributes.places.first(where: { $0.id == context.state.winner }) {
          Image(winner.sticker).resizable().scaledToFit().frame(width: TokSize.iconLg, height: TokSize.iconLg)
        } else {
          Countdown(state: context.state, tok: tok)
        }
      } minimal: {
        LiveDot(tok: tok)
      }
      .keylineTint(tok.bgDanger)
      .widgetURL(pollURL)
    }
  }
}

/// Opens the app on the poll, open.
private let pollURL = URL(string: "tripup://poll")

/// The lock screen: the live line and countdown, the question, and the places. Light or dark with the system.
struct PollLockScreen: View {
  let context: ActivityViewContext<PollActivityAttributes>
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let tok = scheme == .dark ? TokColors.dark : TokColors.light
    // A Live Activity has 160 points of height: every gap here is counted
    VStack(alignment: .leading, spacing: TokSpace.xs) {
      VStack(alignment: .leading, spacing: TokSpace.x3xs) {
        HStack(spacing: TokSpace.xs) {
          LiveLine(state: context.state, tok: tok)
          Spacer(minLength: 0)
          Countdown(state: context.state, tok: tok)
        }
        Text(title)
          .font(TokText.headingSm)
          .foregroundStyle(tok.textDefault)
          .lineLimit(1)
      }
      PlaceCards(context: context, tok: tok)
    }
    .padding(.horizontal, TokSpace.md)
    .padding(.vertical, TokSpace.sm)
    .activityBackgroundTint(tok.bgDefault)
    .activitySystemActionForegroundColor(tok.textBrand)
  }

  private var title: String {
    if let winner = context.attributes.places.first(where: { $0.id == context.state.winner }) {
      return "Tonight: \(winner.name)"
    }
    return context.attributes.question
  }
}

/// "Live poll • 2 of 5 voted" with the red dot after it, as on the app's card; once it's closed, that it's decided.
/// [short] for the Island's narrow corner: "2/5 voted".
struct LiveLine: View {
  let state: PollActivityAttributes.ContentState
  let tok: TokColors
  var short = false

  var body: some View {
    HStack(spacing: TokSpace.xs) {
      Text(text)
        .font(TokText.labelMd.weight(.semibold))
        .foregroundStyle(state.winner == nil ? tok.textBrand : tok.textMuted)
        .contentTransition(.numericText(value: Double(state.voted)))
        .lineLimit(1)
      if state.winner == nil { LiveDot(tok: tok) }
    }
  }

  private var text: String {
    if short { return "\(state.voted)/\(state.table) voted" }
    return state.winner == nil ? "Live poll • \(state.voted) of \(state.table) voted" : "Poll closed • \(state.voted) of \(state.table) voted"
  }
}

/// The time left, counting down on its own (the system runs it; nothing animates it).
struct Countdown: View {
  let state: PollActivityAttributes.ContentState
  let tok: TokColors

  var body: some View {
    if state.winner != nil {
      Text("Decided").font(TokText.labelMd.weight(.semibold)).foregroundStyle(tok.textMuted)
    } else {
      // A timer text takes all the width it's given, so it gets just enough for "29:59"
      Text(timerInterval: Date.now...max(Date.now, state.closesAt), countsDown: true)
        .monospacedDigit()
        .font(TokText.labelMd.weight(.semibold))
        .foregroundStyle(tok.textBrand)
        .multilineTextAlignment(.trailing)
        .frame(width: pollActivityTimer, alignment: .trailing)
    }
  }
}

/// The red "live" dot.
struct LiveDot: View {
  let tok: TokColors

  var body: some View {
    Circle().fill(tok.bgDanger).frame(width: TokDim.pollLiveDot, height: TokDim.pollLiveDot)
  }
}

/// The three places side by side. They keep their order whatever the count, so nothing jumps.
struct PlaceCards: View {
  let context: ActivityViewContext<PollActivityAttributes>
  let tok: TokColors

  var body: some View {
    HStack(spacing: TokSpace.xs) {
      ForEach(context.attributes.places, id: \.id) { place in
        if context.state.winner == nil {
          // The whole card votes (or moves my vote here)
          Button(intent: PollVoteIntent(place: place.id)) { PlaceCard(place: place, state: context.state, tok: tok) }
            .buttonStyle(.plain)
            .accessibilityLabel(context.state.mine == place.id ? "Your vote: \(place.name)" : "Vote for \(place.name)")
        } else {
          PlaceCard(place: place, state: context.state, tok: tok)
        }
      }
    }
  }
}

/// One place, small: its sticker and the vote mark (filled in brand once it's mine, or the winner's), its name, and
/// a bar of its votes with the count. My pick sits on brand-subtle; once closed, the others fade back.
struct PlaceCard: View {
  let place: PollActivityAttributes.Place
  let state: PollActivityAttributes.ContentState
  let tok: TokColors

  var body: some View {
    let votes = state.votes[place.id] ?? 0
    let share = state.table > 0 ? CGFloat(votes) / CGFloat(state.table) : 0
    let picked = state.winner.map { $0 == place.id } ?? (state.mine == place.id)
    VStack(alignment: .leading, spacing: TokSpace.x2xs) {
      HStack(alignment: .top) {
        Image(place.sticker).resizable().scaledToFit().frame(width: TokDim.stickerMini, height: TokDim.stickerMini)
        Spacer(minLength: 0)
        Mark(on: picked, tok: tok)
      }
      HStack(spacing: TokSpace.x2xs) {
        Text(place.short)
          .font(TokText.labelMd)
          .foregroundStyle(tok.textDefault)
          .lineLimit(1)
        Spacer(minLength: 0)
        Text("\(votes)")
          .font(TokText.labelSm)
          .foregroundStyle(tok.textMuted)
          .contentTransition(.numericText(value: Double(votes)))
      }
      // The bar grows from the left (a scale, so its rounded end keeps its shape)
      Capsule()
        .fill(tok.bgDefault)
        .frame(height: pollActivityBar)
        .overlay(alignment: .leading) {
          Capsule().fill(tok.bgBrand).scaleEffect(x: share, anchor: .leading)
        }
    }
    .padding(TokSpace.xs)
    .frame(maxWidth: .infinity)
    .background(RoundedRectangle(cornerRadius: TokRadius.card).fill(picked ? tok.bgBrandSubtle : tok.bgSubtle))
    .opacity(state.winner != nil && !picked ? TokDim.pollLostOpacity : 1)
  }
}

/// The vote mark: an empty ring, or filled in brand with a check once it's mine.
struct Mark: View {
  let on: Bool
  let tok: TokColors

  var body: some View {
    ZStack {
      Circle().strokeBorder(tok.borderStrong, lineWidth: on ? 0 : pollMarkRing)
      Circle().fill(tok.bgBrand).opacity(on ? 1 : 0)
      Image(systemName: "checkmark")
        .font(TokText.caption.weight(.bold))
        .foregroundStyle(tok.textOnBrand)
        .opacity(on ? 1 : 0)
    }
    .frame(width: pollActivityMark, height: pollActivityMark)
  }
}
