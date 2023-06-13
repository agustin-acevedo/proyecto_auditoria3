import SwiftUI

struct SettingsTextEditView: UIViewControllerRepresentable {
    let value: String?
    let placeholder: String
    var hint: String?
    let onCommit: ((String)) -> Void

    func makeUIViewController(context: Context) -> SettingsTextViewController {
        let viewController = SettingsTextViewController(text: value ?? "", placeholder: placeholder, hint: hint ?? "")
        viewController.onValueChanged = onCommit
        return viewController
    }

    func updateUIViewController(_ viewController: SettingsTextViewController, context: Context) {
        // Do nothing
    }
}

struct LanguagePickerView: UIViewControllerRepresentable {
    let blog: Blog
    var onChange: (NSNumber) -> Void

    func makeUIViewController(context: Context) -> LanguageViewController {
        let viewController = LanguageViewController(blog: blog)
        viewController.onChange = onChange
        // The default `UISearchController` behavior, which is to hide the
        // navigation bar, was not working properly when presenting using
        // `UIViewControllerRepresentable`.
        viewController.hidesNavigationBarDuringPresentation = false
        return viewController
    }

    func updateUIViewController(_ viewController: LanguageViewController, context: Context) {
        // Do nothing
    }
}
