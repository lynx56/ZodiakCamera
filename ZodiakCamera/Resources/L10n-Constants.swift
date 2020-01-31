// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
internal enum L10n {

  internal enum NoConnection {
    /// No connection...
    internal static let text = L10n.tr("Localizable", "NoConnection.Text")
  }

  internal enum Settings {
    /// Access settings
    internal static let access = L10n.tr("Localizable", "Settings.Access")
    /// Address
    internal static let address = L10n.tr("Localizable", "Settings.Address")
    /// Host
    internal static let host = L10n.tr("Localizable", "Settings.Host")
    /// Login
    internal static let login = L10n.tr("Localizable", "Settings.Login")
    /// Password
    internal static let password = L10n.tr("Localizable", "Settings.Password")
    /// Port
    internal static let port = L10n.tr("Localizable", "Settings.Port")
    /// Save
    internal static let save = L10n.tr("Localizable", "Settings.Save")
    /// Saved
    internal static let saved = L10n.tr("Localizable", "Settings.Saved")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // swiftlint:disable:next nslocalizedstring_key
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
