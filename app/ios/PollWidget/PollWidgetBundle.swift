// The widget extension: only the dinner poll's Live Activity for now.
import SwiftUI
import WidgetKit

@main
struct PollWidgetBundle: WidgetBundle {
  var body: some Widget {
    PollLiveActivity()
  }
}
