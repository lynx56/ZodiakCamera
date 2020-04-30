// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
internal enum L10n {

  internal enum AuthViewController {
    /// Confirm passcode.
    internal static let confirmPasscode = L10n.tr("Localizable", "AuthViewController.ConfirmPasscode")
    /// Enter passcode.
    internal static let enterPasscode = L10n.tr("Localizable", "AuthViewController.EnterPasscode")
    /// Saved.
    internal static let passcodeSaved = L10n.tr("Localizable", "AuthViewController.PasscodeSaved")
    /// %@ is locked now, because of too many failed attempts. Enter passcode to unlock %@.
    internal static func reason(_ p1: String, _ p2: String) -> String {
      return L10n.tr("Localizable", "AuthViewController.Reason", p1, p2)
    }
    /// %@ or Enter Passcode.
    internal static func title(_ p1: String) -> String {
      return L10n.tr("Localizable", "AuthViewController.Title", p1)
    }
    /// You enter wrong passcode. Try again.
    internal static let wrongPasscode = L10n.tr("Localizable", "AuthViewController.WrongPasscode")
  }

  internal enum Error {
    /// Try again
    internal static let tryAgain = L10n.tr("Localizable", "Error.TryAgain")
    internal enum NoAccess {
      /// Make sure your settings are correct and camera is turned on
      internal static let description = L10n.tr("Localizable", "Error.NoAccess.Description")
      /// No access to camera
      internal static let title = L10n.tr("Localizable", "Error.NoAccess.Title")
    }
    internal enum NoInternetConnection {
      /// Make sure wifi or cellular data is turned on and then try again
      internal static let description = L10n.tr("Localizable", "Error.NoInternetConnection.Description")
      /// No internet connection
      internal static let title = L10n.tr("Localizable", "Error.NoInternetConnection.Title")
    }
  }

  internal enum Settings {
    /// Access settings
    internal static let access = L10n.tr("Localizable", "Settings.Access")
    /// Address
    internal static let address = L10n.tr("Localizable", "Settings.Address")
    /// Passcode or FaceId protection
    internal static let faceId = L10n.tr("Localizable", "Settings.FaceId")
    /// Host
    internal static let host = L10n.tr("Localizable", "Settings.Host")
    /// Login
    internal static let login = L10n.tr("Localizable", "Settings.Login")
    /// Password
    internal static let password = L10n.tr("Localizable", "Settings.Password")
    /// Passcode protection
    internal static let pinProtection = L10n.tr("Localizable", "Settings.PinProtection")
    /// Port
    internal static let port = L10n.tr("Localizable", "Settings.Port")
    /// Field must contains ip or url address
    internal static let ruleInvalidHost = L10n.tr("Localizable", "Settings.RuleInvalidHost")
    /// Field required
    internal static let ruleRequired = L10n.tr("Localizable", "Settings.RuleRequired")
    /// Save
    internal static let save = L10n.tr("Localizable", "Settings.Save")
    /// Saved
    internal static let saved = L10n.tr("Localizable", "Settings.Saved")
    /// Passcode or TouchId protection
    internal static let touchId = L10n.tr("Localizable", "Settings.TouchId")
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
