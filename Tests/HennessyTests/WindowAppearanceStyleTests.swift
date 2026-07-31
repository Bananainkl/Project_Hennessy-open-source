import Testing
@testable import Hennessy

struct WindowAppearanceStyleTests {
    @Test func rawValuesRemainStableForStoredPreferences() {
        #expect(WindowAppearanceStyle(rawValue: "glass") == .glass)
        #expect(WindowAppearanceStyle(rawValue: "desktopTransparency") == .desktopTransparency)
    }

    @Test func everyStyleProvidesUserFacingMetadata() {
        for style in WindowAppearanceStyle.allCases {
            #expect(!style.title.isEmpty)
            #expect(!style.icon.isEmpty)
            #expect(!style.detail.isEmpty)
        }
    }
}
