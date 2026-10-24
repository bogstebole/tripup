// The dinner poll on the lock screen and in the Dynamic Island, with a vote button per place. It's the app's poll card
// (Bogdan's design, Figma 82:3) made to fit: the live sign and countdown, the question, and each place with its
// sticker, a bar of its votes and the vote. The lock screen is light, the Island dark, both from the app's tokens.
import ActivityKit
import SwiftUI
import WidgetKit

struct PollLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: PollActivityAttributes.self) { context in
      PollLockScreen(context: context)
        .activityBackgroundTint(TokColors.light.bgDefault)
        .activitySystemActionForegroundColor(TokColors.light.textBrand)
    } dynamicIsland: { context in
      let tok = TokColors.dark
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          LiveLabel(state: context.state, tok: tok, short: true).padding(.leading, TokSpace.x2xs)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Countdown(state: context.state, tok: tok).padding(.trailing, TokSpace.x2xs)
        }
        // The Island has room for the places, not the question too
        DynamicIslandExpandedRegion(.bottom) {
          Places(context: context, tok: tok).padding(.horizontal, TokSpace.x2xs)
        }
      } compactLeading: {
        HStack(spacing: TokSpace.x2xs) {
          LiveDot(tok: tok)
          Text(context.state.winner == nil ? "Poll" : "Dinner").font(TokText.labelMd.weight(.semibold)).foregroundStyle(tok.textDefault)
        }
      } compactTrailing: {
        if let winner = context.attributes.places.first(where: { $0.id == context.state.winner }) {
          Image(winner.sticker).resizable().scaledToFit().frame(width: TokDim.stickerChip, height: TokDim.stickerChip)
        } else {
          Countdown(state: context.state, tok: tok)
        }
      } minimal: {
        LiveDot(tok: tok)
      }
      .keylineTint(tok.cPollLive)
    }
  }
}

/// The lock screen: who asked and the countdown, the question, and the places.
struct PollLockScreen: View {
  let context: ActivityViewContext<PollActivityAttributes>

  var body: some View {
    let tok = TokColors.light
    VStack(alignment: .leading, spacing: TokSpace.xs) {
      HStack(spacing: TokSpace.xs) {
        LiveLabel(state: context.state, tok: tok)
        Spacer(minLength: 0)
        Countdown(state: context.state, tok: tok)
      }
      Text(title)
        .font(TokText.headingMd)
        .foregroundStyle(tok.textDefault)
        .lineLimit(1)
      Places(context: context, tok: tok)
    }
    .padding(TokSpace.md)
  }

  private var title: String {
    if let winner = context.attributes.places.first(where: { $0.id == context.state.winner }) {
      return "Tonight: \(winner.short), 5 PM"
    }
    return context.attributes.question
  }
}

/// "Live poll" with the red dot and how many have voted, or once it's closed, that it's decided. [short] for the
/// Island's narrow corner: "Dinner poll · 2/5".
struct LiveLabel: View {
  let state: PollActivityAttributes.ContentState
  let tok: TokColors
  var short = false

  var body: some View {
    HStack(spacing: TokSpace.xs) {
      if state.winner == nil { LiveDot(tok: tok) }
      Text(short
          ? "Dinner poll · \(state.voted)/\(state.table)"
          : state.winner == nil ? "Live poll · \(state.voted) of \(state.table) voted" : "Poll closed · \(state.voted) of \(state.table) voted")
        .font(TokText.labelMd.weight(.semibold))
        .foregroundStyle(state.winner == nil ? tok.textBrand : tok.textMuted)
        .contentTransition(.numericText(value: Double(state.voted)))
        .lineLimit(1)
    }
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
        .frame(width: TokDim.pollActivityTimer, alignment: .trailing)
    }
  }
}

/// The red "live" dot.
struct LiveDot: View {
  let tok: TokColors

  var body: some View {
    Circle().fill(tok.cPollLive).frame(width: TokDim.pollLiveDot, height: TokDim.pollLiveDot)
  }
}

/// Each place: its sticker, short name and vote count, a bar of its votes, and the vote. The places keep their order
/// whatever the count (nothing jumps); the one ahead is in brand.
struct Places: View {
  let context: ActivityViewContext<PollActivityAttributes>
  let tok: TokColors

  var body: some View {
    let state = context.state
    let lead = state.votes.max(by: { $0.value < $1.value })?.key
    VStack(spacing: TokSpace.x2xs) {
      ForEach(context.attributes.places, id: \.id) { place in
        let votes = state.votes[place.id] ?? 0
        let share = state.table > 0 ? CGFloat(votes) / CGFloat(state.table) : 0
        let ahead = state.winner.map { $0 == place.id } ?? (votes > 0 && place.id == lead)
        HStack(spacing: TokSpace.sm) {
          Image(place.sticker).resizable().scaledToFit().frame(width: TokDim.stickerChip, height: TokDim.stickerChip)
          VStack(alignment: .leading, spacing: TokSpace.x3xs) {
            HStack {
              Text(place.short).font(TokText.labelMd).foregroundStyle(tok.textDefault).lineLimit(1)
              Spacer(minLength: TokSpace.xs)
              Text("\(votes)")
                .font(TokText.labelSm)
                .foregroundStyle(tok.textMuted)
                .contentTransition(.numericText(value: Double(votes)))
            }
            // The bar grows from the left (a scale, so its rounded end keeps its shape)
            Capsule()
              .fill(tok.cPollBarTrack)
              .frame(height: TokDim.pollActivityBar)
              .overlay(alignment: .leading) {
                Capsule()
                  .fill(ahead ? tok.cPollBarLead : tok.cPollBar)
                  .scaleEffect(x: share, anchor: .leading)
              }
          }
          if state.winner == nil {
            Button(intent: PollVoteIntent(place: place.id)) {
              VoteMark(on: state.mine == place.id, tok: tok)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(state.mine == place.id ? "Your vote: \(place.name)" : "Vote for \(place.name)")
          }
        }
      }
    }
  }
}

/// The vote: a soft circle with a check, filled in brand once it's yours.
struct VoteMark: View {
  let on: Bool
  let tok: TokColors

  var body: some View {
    ZStack {
      Circle().fill(on ? tok.bgBrand : tok.bgMuted)
      Image(systemName: "checkmark")
        .font(TokText.labelSm.weight(.bold))
        .foregroundStyle(on ? tok.textOnBrand : tok.textDefault)
    }
    .frame(width: TokDim.pollActivityMark, height: TokDim.pollActivityMark)
    .contentTransition(.opacity)
  }
}
