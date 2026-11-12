@testable import PlaylisterData
import Testing

struct RecommendationsCollectorTests {
    private static func collector(recommendations: Int = 20, search: Int = 100) -> RecommendationsCollector<String> {
        let limits = PlaylistsLimits(recommendations: recommendations, recommendationsSearch: search, library: 20)
        return RecommendationsCollector(term: "Hitster", limits: limits) { $0 }
    }

    @Test func keepsOnlyNamesThatContainTheTermIgnoringCaseAndAccents() {
        var collector = Self.collector()
        collector.add(["Hitster España", "Éxitos 80s", "HITSTER rock", "hítster", "Fiesta"])
        #expect(collector.items == ["Hitster España", "HITSTER rock", "hítster"])
        #expect(!collector.isComplete)
    }

    @Test func stopsOnceItHasEnoughRecommendations() {
        var collector = Self.collector(recommendations: 2)
        collector.add(["Hitster 1", "Other", "Hitster 2", "Hitster 3"])
        #expect(collector.items == ["Hitster 1", "Hitster 2"])
        #expect(collector.readCount == 3)
        #expect(collector.isComplete)
    }

    @Test func stopsOnceTheSearchLimitIsRead() {
        var collector = Self.collector(search: 3)
        collector.add(["Other 1", "Hitster 1"])
        collector.add(["Other 2", "Hitster 2"])
        #expect(collector.items == ["Hitster 1"])
        #expect(collector.readCount == 3)
        #expect(collector.isComplete)
    }
}
