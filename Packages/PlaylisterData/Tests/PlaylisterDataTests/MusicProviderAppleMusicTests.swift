@testable import PlaylisterData
import Testing

struct MusicProviderAppleMusicTests {
    @Test func freeModeUsesTheAppleMusicServices() {
        #expect(MusicProvider.free.usesAppleMusic)
        #expect(MusicProvider.appleMusic.usesAppleMusic)
        #expect(!MusicProvider.spotify.usesAppleMusic)
    }

    @Test func registersTheServiceUnderAppleMusicAndFreeMode() {
        let services = MusicProvider.appleMusicServices("service")

        #expect(services == [.appleMusic: "service", .free: "service"])
    }
}
