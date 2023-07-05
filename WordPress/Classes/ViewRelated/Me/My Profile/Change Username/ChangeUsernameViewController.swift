import Combine
import WordPressAuthenticator

class ChangeUsernameViewController: SignupUsernameTableViewController {
    typealias CompletionBlock = (String?) -> Void

    override var analyticsSource: String {
        return "account_settings"
    }
    private let viewModel: ChangeUsernameViewModel
    private let completionBlock: CompletionBlock
    private lazy var saveBarButtonItem: UIBarButtonItem = {
        let saveItem = UIBarButtonItem(title: Constants.actionButtonTitle, style: .plain, target: nil, action: nil)
        saveItem.on() { [weak self] _ in
            self?.save()
        }
        return saveItem
    }()

    init(service: AccountSettingsService, settings: AccountSettings?, completionBlock: @escaping CompletionBlock) {
        self.viewModel = ChangeUsernameViewModel(service: service, settings: settings)
        self.completionBlock = completionBlock
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.start()
    }

    override func buildHeaderDescription() -> NSAttributedString {
        return viewModel.headerDescription()
    }

    override func startSearch(for searchTerm: String) {
        saveBarButtonItem.isEnabled = false
        viewModel.suggestUsernames(for: searchTerm, reloadingAllSections: false)

        trackSearchPerformed()
    }
}

private extension ChangeUsernameViewController {
    func setupViewModel() {
        let reloadSaveButton: ChangeUsernameViewModel.Listener = { [weak self] in
            self?.setNeedsSaveButtonIsEnabled()
        }
        viewModel.reachabilityListener = reloadSaveButton
        viewModel.selectedUsernameListener = reloadSaveButton
        viewModel.keyboardListener = { [weak self] notification in
            self?.adjustForKeyboard(notification: notification)
        }
        viewModel.suggestionsListener = { [weak self] state, suggestions, reloadAllSections in
            switch state {
            case .loading:
                self?.showLoader()
            case .success:
                if suggestions.isEmpty {
                    WPAppAnalytics.track(.accountSettingsChangeUsernameSuggestionsFailed)
                }
                self?.hideLoader()
                self?.suggestions = suggestions
                self?.reloadSections(includingAllSections: reloadAllSections)
            default:
                break
            }
        }
        currentUsername = viewModel.username
        delegate = viewModel
    }

    func setupUI() {
        navigationItem.title = Constants.username
        navigationItem.rightBarButtonItems = [saveBarButtonItem]

        registerNibs()
        setupBackgroundTapGestureRecognizer()
        setNeedsSaveButtonIsEnabled()
    }

    func setNeedsSaveButtonIsEnabled() {
        saveBarButtonItem.isEnabled = viewModel.isReachable && viewModel.usernameIsValidToBeChanged
    }

    func adjustForKeyboard(notification: Foundation.Notification) {
        let wrappedRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let keyboardRect = wrappedRect?.cgRectValue ?? CGRect.zero
        let relativeRect = view.convert(keyboardRect, from: nil)
        let bottomInset = max(relativeRect.height - relativeRect.maxY + view.frame.height, 0)
        var insets = tableView.contentInset
        insets.bottom = bottomInset
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
    }

    func save() {
        let controller = UIAlertController.confirmationPrompt(forSelectedUsername: viewModel.selectedUsername) { [weak self] in
            self?.changeUsername()
        }
        present(controller, animated: true)
    }

    func changeUsername() {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()

        viewModel.save() { [weak self] (state, error) in
            SVProgressHUD.setDefaultMaskType(.none)
            switch state {
            case .success:
                WPAppAnalytics.track(.accountSettingsChangeUsernameSucceeded)
                SVProgressHUD.dismiss()
                self?.completionBlock(self?.viewModel.selectedUsername)
                self?.navigationController?.popViewController(animated: true)
            case .failure:
                WPAppAnalytics.track(.accountSettingsChangeUsernameFailed)
                SVProgressHUD.showError(withStatus: error)
            default:
                break
            }
        }
    }

    enum Constants {
        static let actionButtonTitle = NSLocalizedString("Save", comment: "Settings Text save button title")
        static let username = NSLocalizedString("Username", comment: "The header and main title")
        static let cellIdentifier = "SearchTableViewCell"

        enum Alert {
            static let loading = NSLocalizedString("Loading usernames", comment: "Shown while the app waits for the username suggestions web service to return during the site creation process.")
            static let title = NSLocalizedString("Careful!", comment: "Alert title.")
            static let message = NSLocalizedString("You are changing your username to %@. Changing your username will also affect your Gravatar profile and IntenseDebate profile addresses. \nConfirm your new username to continue.", comment: "Alert message.")
            static let cancel = NSLocalizedString("Cancel", comment: "Cancel button.")
            static let change = NSLocalizedString("Change username", comment: "Change button.")
            static let confirm = NSLocalizedString("Confirm username", comment: "Alert text field placeholder.")
        }
    }
}

private extension UIAlertController {
    static var cancellableKey = 0

    static func confirmationPrompt(forSelectedUsername selectedUsername: String, confirmed: @escaping () -> Void) -> UIAlertController {
        typealias Constants = ChangeUsernameViewController.Constants
        let alertController = UIAlertController(title: Constants.Alert.title, message: "", preferredStyle: .alert)
        alertController.addAttributeMessage(String(format: Constants.Alert.message, selectedUsername),
                                            highlighted: selectedUsername)
        alertController.addCancelActionWithTitle(Constants.Alert.cancel, handler: { _ in
            DDLogInfo("User cancelled alert")
        })

        let action = alertController.addDefaultActionWithTitle(Constants.Alert.change, handler: { [weak alertController] _ in
            guard let alertController else { return }
            guard let textField = alertController.textFields?.first,
                textField.text == selectedUsername else {
                    DDLogInfo("Username confirmation failed")
                    return
            }
            DDLogInfo("User changes username")
            confirmed()
        })
        action.isEnabled = false

        alertController.addTextField { [weak action, unowned alertController] textField in
            textField.placeholder = Constants.Alert.confirm

            let cancellable = NotificationCenter.default
                .publisher(for: UITextField.textDidChangeNotification, object: textField)
                .sink(receiveValue: { [weak action, weak textField] _ in
                    let enabled = textField?.text?.isEmpty == false && textField?.text == selectedUsername
                    action?.isEnabled = enabled
                    textField?.textColor = enabled ? .success : .text
                })
            // Bind the subscription with the lifetime of the alert. When the alert instance is released, `cancellable` will be
            // released too which will automatically unregister the notification observer.
            objc_setAssociatedObject(alertController, &UIAlertController.cancellableKey, cancellable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        DDLogInfo("Prompting user for confirmation of change username")

        return alertController
    }

    func addAttributeMessage(_ message: String, highlighted text: String) {
        let paragraph = String(format: message, text)
        let font = WPStyleGuide.fontForTextStyle(.footnote)
        let bold = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .bold)

        let attributed = NSMutableAttributedString(string: paragraph, attributes: [.font: font])
        attributed.applyStylesToMatchesWithPattern("\\b\(text)", styles: [.font: bold])
        setValue(attributed, forKey: "attributedMessage")
    }
}
