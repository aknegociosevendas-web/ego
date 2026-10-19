import SwiftUI
import WidgetKit

@main
struct EGOWidgetsBundle: WidgetBundle {
    init() {
        // The widget runs in its own process — register the brand font here too.
        DS.Fonts.registerIfNeeded()
    }

    var body: some Widget {
        FocusLiveActivity()
    }
}
