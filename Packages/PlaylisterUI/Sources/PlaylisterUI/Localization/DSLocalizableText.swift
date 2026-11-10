import Foundation

/// Components that display text conform to this protocol and get `.localized(_:)` for free.
@MainActor
public protocol DSLocalizableText {
    /// The text the component shows (title, label or placeholder).
    var text: String { get set }
}

public extension DSLocalizableText {
    /// Returns a copy of the component whose text is the localised value of `key`.
    ///
    ///     DSText(style: .title).localized("profile.title")
    ///     DSButton { save() }.localized("profile.save")
    ///
    /// - Parameters:
    ///   - key: Key in the String Catalog (`Localizable.xcstrings` of the app by default).
    ///   - table: String table name. `nil` uses `Localizable`.
    ///   - bundle: Bundle that holds the catalog. Defaults to the app bundle.
    func localized(_ key: String, table: String? = nil, bundle: Bundle = .main) -> Self {
        var copy = self
        copy.text = String(localized: String.LocalizationValue(key), table: table, bundle: bundle)
        return copy
    }
}
