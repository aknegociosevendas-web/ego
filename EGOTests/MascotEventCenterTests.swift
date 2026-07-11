import Foundation
import Testing
@testable import EGO

@MainActor
struct MascotEventCenterTests {
    @Test func flashRevertsToBaseline() async throws {
        let center = MascotEventCenter(reactionDuration: 0.05)
        center.updateBaseline(.worried)
        #expect(center.state == .worried)

        center.sessionCompleted()
        #expect(center.state == .happy)

        try await Task.sleep(for: .milliseconds(300))
        #expect(center.state == .worried)
    }

    @Test func baselineChangeDoesNotInterruptStudying() {
        let center = MascotEventCenter(reactionDuration: 0.05)
        center.focusStarted()
        center.updateBaseline(.worried)
        #expect(center.state == .studying)

        center.focusStopped()
        #expect(center.state == .worried)
    }

    @Test func clearingWorriedBaselineReturnsToIdle() {
        let center = MascotEventCenter(reactionDuration: 0.05)
        center.updateBaseline(.worried)
        center.updateBaseline(.idle)
        #expect(center.state == .idle)
    }
}
