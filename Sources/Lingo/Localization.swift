import Foundation

public enum Localization {
    
    case universal(value: String)
    case pluralized(values: [PluralCategory: String])
    
    func value(forLocale locale: LocaleIdentifier, interpolations: [String: Any]? = nil) -> String {
        switch self {
            case .universal(let rawString):
                return self.interpolate(rawString, interpolations: interpolations)
            
            case .pluralized(let values):
                let pluralCategory = self.pluralCategory(for: locale, interpolations: interpolations)
                guard let rawString = values[pluralCategory] else {
                    assertionFailure("Missing plural value for category: \(pluralCategory)")
                    return ""
                }
                
                return self.interpolate(rawString, interpolations: interpolations)
        }
    }
    
}

fileprivate extension Localization {
    
    static let interpolator = StringInterpolator()

    /// Returns string by interpolating rawString with passed interpolations
    func interpolate(_ rawString: String, interpolations: [String: Any]?) -> String {
        guard let interpolations = interpolations else {
            return rawString
        }
        
        return Localization.interpolator.interpolate(rawString, with: interpolations)
    }
    
    /// The PluralCategory is based on the first numeric value in `interpolations` and `PluralizationRule` for the given language.
    /// If no numeric value is found, it fallbacks to `.other`.
    func pluralCategory(`for` locale: LocaleIdentifier, interpolations: [String: Any]?) -> PluralCategory {
        guard let pluralizationRule = PluralizationRuleStore.pluralizationRule(forLocale: locale) else {
            assertionFailure("Missing pluralization rule for locale: \(locale). Will default to `other` rule.")
            return .other
        }
        
        if let interpolations = interpolations, let numericValue = self.extractNumericValue(from: interpolations) {
            return pluralizationRule.pluralCategory(forNumericValue: numericValue)
        }
        
        return .other
    }
    
    /// Extract the first numeric value from the interpolations and make it non negative.
    /// Currently we do not support localizations with more than one plural category (example: you have 1 unread message and 6 unread emails.),
    /// so the first numerical value that is found will be used for pluralization rules.
    func extractNumericValue(from interpolations: [String: Any]) -> UInt? {
        for value in interpolations.values {
            if var intValue = value as? Int {
                // Make sure the value is positive
                if intValue < 0 {
                    intValue *= -1
                }
                
                return UInt(intValue)
            }
        }
        
        return nil
    }
    
}
