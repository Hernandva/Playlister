@testable import PlaylisterUI
import Testing

@MainActor
struct LocalizedTests {
    @Test func returnsTheKeyWhenItIsNotInTheCatalog() {
        let text = DSText(style: .title).localized("missing.key")
        #expect(text.text == "missing.key")
    }

    @Test func keepsTheOriginalComponentUnchanged() {
        let original = DSButton("Original") {}
        _ = original.localized("missing.key")
        #expect(original.text == "Original")
    }
}
