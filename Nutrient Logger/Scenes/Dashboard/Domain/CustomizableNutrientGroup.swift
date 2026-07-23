//
//  CustomizableNutrientGroup.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

/// The four nutrient groups on the Nutrition tab whose order and visible-count the user can
/// customize (Carbohydrates is fixed and not included). Owns the `@AppStorage` key names so the
/// dashboard sections, the settings sheet, and onboarding personalization all agree on them.
enum CustomizableNutrientGroup: String, CaseIterable, Identifiable, Sendable {
    case vitamins
    case minerals
    case lipids
    case aminoAcids

    var id: String { rawValue }

    /// Comma-separated ordered nutrient IDs. Empty means "use the section's default whitelist".
    var orderStorageKey: String { "nutrientCustomize_\(rawValue)_order" }

    /// Comma-separated hidden nutrient IDs.
    var hiddenStorageKey: String { "nutrientCustomize_\(rawValue)_hidden" }

    /// How many nutrients show before the "More" button. Defaults to `defaultVisibleCount`.
    var visibleCountStorageKey: String { "nutrientCustomize_\(rawValue)_visibleCount" }

    /// Nutrients shown above the "More" fold by default.
    static let defaultVisibleCount = 3
}
