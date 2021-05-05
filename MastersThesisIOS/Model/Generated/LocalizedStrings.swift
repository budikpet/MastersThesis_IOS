// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {

  internal enum AnimalDetail {
    /// Biotop
    internal static let labelBiotop = L10n.tr("Localizable", "animalDetail.labelBiotop")
    /// Class
    internal static let labelClass = L10n.tr("Localizable", "animalDetail.labelClass")
    /// Continent
    internal static let labelContinent = L10n.tr("Localizable", "animalDetail.labelContinent")
    /// Food
    internal static let labelFood = L10n.tr("Localizable", "animalDetail.labelFood")
    /// Location in Zoo Prague
    internal static let labelLocation = L10n.tr("Localizable", "animalDetail.labelLocation")
    /// Name
    internal static let labelName = L10n.tr("Localizable", "animalDetail.labelName")
    /// Order
    internal static let labelOrder = L10n.tr("Localizable", "animalDetail.labelOrder")
    /// Reproduction
    internal static let labelReproduction = L10n.tr("Localizable", "animalDetail.labelReproduction")
    /// Sizes
    internal static let labelSizes = L10n.tr("Localizable", "animalDetail.labelSizes")
  }

  internal enum AnimalFilter {
    /// Biotop
    internal static let biotop = L10n.tr("Localizable", "animalFilter.biotop")
    /// Class
    internal static let `class` = L10n.tr("Localizable", "animalFilter.class_")
    /// Food
    internal static let food = L10n.tr("Localizable", "animalFilter.food")
    /// Zoo house
    internal static let zooHouse = L10n.tr("Localizable", "animalFilter.zooHouse")
  }

  internal enum Basic {
    /// Error
    internal static let error = L10n.tr("Localizable", "basic.error")
    /// OK
    internal static let ok = L10n.tr("Localizable", "basic.ok")
    /// Show more
    internal static let showMore = L10n.tr("Localizable", "basic.show_more")
    internal enum Error {
      /// Something went wrong.
      internal static let message = L10n.tr("Localizable", "basic.error.message")
    }
  }

  internal enum Errors {
    /// Image is missing.
    internal static let missingImage = L10n.tr("Localizable", "errors.missingImage")
  }

  internal enum Label {
    /// External animal pen
    internal static let externalPen = L10n.tr("Localizable", "label.externalPen")
  }

  internal enum Lexicon {
    /// Updating lexicon...
    internal static let updatingDB = L10n.tr("Localizable", "lexicon.updatingDB")
  }

  internal enum Map {
    /// View animals
    internal static let buttonViewAnimals = L10n.tr("Localizable", "map.buttonViewAnimals")
    /// Database is being updated...
    internal static let isUpdating = L10n.tr("Localizable", "map.isUpdating")
    /// GPS location services not available
    internal static let locationUnavailable = L10n.tr("Localizable", "map.locationUnavailable")
    /// User is outside of the map
    internal static let notInMap = L10n.tr("Localizable", "map.notInMap")
    /// Selected %d features
    internal static func selectedFeatures(_ p1: Int) -> String {
      return L10n.tr("Localizable", "map.selectedFeatures", p1)
    }
    /// Selected %d features
    internal static func selectedFeaturesMultiple(_ p1: Int) -> String {
      return L10n.tr("Localizable", "map.selectedFeaturesMultiple", p1)
    }
    /// Too many selected
    internal static let tooManyValues = L10n.tr("Localizable", "map.tooManyValues")
    internal enum ButtonDirections {
      /// Directions
      internal static let start = L10n.tr("Localizable", "map.buttonDirections.start")
      /// Stop directing
      internal static let stop = L10n.tr("Localizable", "map.buttonDirections.stop")
    }
  }

  internal enum NavigationItem {
    internal enum Title {
      /// Lexicon filter
      internal static let animalFilter = L10n.tr("Localizable", "navigationItem.title.animalFilter")
      /// Animal lexicon
      internal static let lexicon = L10n.tr("Localizable", "navigationItem.title.lexicon")
      /// Zoo Map
      internal static let zooMap = L10n.tr("Localizable", "navigationItem.title.zooMap")
    }
  }

  internal enum Tab {
    /// Lexicon
    internal static let lexicon = L10n.tr("Localizable", "tab.lexicon")
    /// Map
    internal static let zooMap = L10n.tr("Localizable", "tab.zooMap")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
