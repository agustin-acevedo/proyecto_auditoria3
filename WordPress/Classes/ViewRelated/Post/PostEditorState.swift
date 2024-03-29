import Foundation
import WordPressShared

/// The various states of the editor interface and all associated UI values
///
/// None of the associated values should be (nor can be) accessed directly by the UI, only through the `PostEditorStateContext` instance.
///
public enum PostEditorAction {
    /// - note: Deprecated (kahu-offline-mode)
    case save
    /// - note: Deprecated (kahu-offline-mode)
    case saveAsDraft
    case schedule
    case publish
    case update
    case submitForReview
    case continueFromHomepageEditing

    /// - note: Deprecated (kahu-offline-mode)
    var dismissesEditor: Bool {
        switch self {
        case .publish, .schedule, .submitForReview:
            return true
        default:
            return false
        }
    }

    /// - note: Deprecated (kahu-offline-mode)
    var isAsync: Bool {
        switch self {
        case .publish, .schedule, .submitForReview:
            return true
        default:
            return false
        }
    }

    var publishActionLabel: String {
        switch self {
        case .publish:
            return NSLocalizedString("Publish", comment: "Label for the publish (verb) button. Tapping publishes a draft post.")
        case .save:
            return NSLocalizedString("Save", comment: "Save button label (saving content, ex: Post, Page, Comment).")
        case .saveAsDraft:
            return NSLocalizedString("Save as Draft", comment: "Title of button allowing users to change the status of the post they are currently editing to Draft.")
        case .schedule:
            return NSLocalizedString("Schedule", comment: "Schedule button, this is what the Publish button changes to in the Post Editor if the post has been scheduled for posting later.")
        case .submitForReview:
            return NSLocalizedString("Submit for Review", comment: "Submit for review button label (saving content, ex: Post, Page, Comment).")
        case .update:
            return NSLocalizedString("Update", comment: "Update button label (saving content, ex: Post, Page, Comment).")
        case .continueFromHomepageEditing:
            return NSLocalizedString("Continue", comment: "Continue button (used to finish editing the home page during site creation).")
        }
    }

    var publishingActionQuestionLabel: String {
        switch self {
        case .publish:
            return NSLocalizedString("Are you sure you want to publish?", comment: "Title of the message shown when the user taps Publish while editing a post.  Options will be Publish and Keep Editing.")
        case .save:
            return NSLocalizedString("Are you sure you want to save?", comment: "Title of the message shown when the user taps Save while editing a post.  Options will be Save Now and Keep Editing.")
        case .saveAsDraft:
            return NSLocalizedString("Are you sure you want to save as draft?", comment: "Title of the message shown when the user taps Save as Draft while editing a post.  Options will be Save Now and Keep Editing.")
        case .schedule:
            return NSLocalizedString("Are you sure you want to schedule?", comment: "Title of message shown when the user taps Schedule while editing a post. Options will be Schedule and Keep Editing")
        case .submitForReview:
            return NSLocalizedString("Are you sure you want to submit for review?", comment: "Title of message shown when user taps submit for review.")
        case .update:
            return NSLocalizedString("Are you sure you want to update?", comment: "Title of message shown when user taps update.")
            // Note: when continue is pressed with no changes, it will close without prompt
        case .continueFromHomepageEditing:
            return NSLocalizedString("Are you sure you want to update your homepage?", comment: "Title of message shown when user taps continue during homepage editing in site creation.")
        }
    }

    /// - note: Deprecated (kahu-offline-mode)
    var publishingActionLabel: String {
        switch self {
        case .publish:
            return NSLocalizedString("Publishing...", comment: "Text displayed in HUD while a post is being published.")
        case .save, .saveAsDraft:
            return NSLocalizedString("Saving...", comment: "Text displayed in HUD while a post is being saved as a draft.")
        case .schedule:
            return NSLocalizedString("Scheduling...", comment: "Text displayed in HUD while a post is being scheduled to be published.")
        case .submitForReview:
            return NSLocalizedString("Submitting for Review...", comment: "Text displayed in HUD while a post is being submitted for review.")
            // not sure if we want to use "Updating..." or "Publishing..." for home page changes?
            // Note: when continue is pressed with no changes, it will close without prompt
        case .update, .continueFromHomepageEditing:
            return NSLocalizedString("Updating...", comment: "Text displayed in HUD while a draft or scheduled post is being updated.")
        }
    }

    var publishingErrorLabel: String {
        switch self {
        case .publish:
            return NSLocalizedString("Error occurred during publishing", comment: "Text displayed in notice while a post is being published.")
        case .schedule:
            return NSLocalizedString("Error occurred during scheduling", comment: "Text displayed in notice while a post is being scheduled to be published.")
            // Note: when continue is pressed with no changes, it will close without prompt
        case .save, .saveAsDraft, .submitForReview, .update, .continueFromHomepageEditing:
            return NSLocalizedString("Error occurred during saving", comment: "Text displayed in notice after attempting to save a draft post and an error occurred.")
        }
    }

    var analyticsEndOutcome: PostEditorAnalyticsSession.Outcome {
        switch self {
        case .save, .saveAsDraft, .update:
            return .save
            // TODO: make a new analytics event(s) for site creation homepage changes
        case .publish, .schedule, .submitForReview, .continueFromHomepageEditing:
            return .publish
        }
    }

    /// - note: deprecated (kahu-offline-mode)
    fileprivate var secondaryPublishAction: PostEditorAction? {
        switch self {
        case .publish:
            return .saveAsDraft
        case .update:
            return .publish
        default:
            return nil
        }
    }

    fileprivate var publishActionAnalyticsStat: WPAnalyticsStat {
        switch self {
        case .save:
            return .editorSavedDraft
        case .saveAsDraft:
            return .editorQuickSavedDraft
        case .schedule:
            return .editorScheduledPost
        case .publish:
            return .editorPublishedPost
            // TODO: make a new analytics event(s)
        case .update, .continueFromHomepageEditing:
            return .editorUpdatedPost
        case .submitForReview:
            // TODO: When support is added for submit for review, add a new stat to support it
            return .editorPublishedPost
        }
    }
}

public protocol PostEditorStateContextDelegate: AnyObject {
    func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction)
    func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool)
}

/// Encapsulates all of the editor UI state based upon actions performed on the post being edited.
///
public class PostEditorStateContext {
    var action: PostEditorAction = .publish {
        didSet {
            if oldValue != action {
                delegate?.context(self, didChangeAction: action)
            }
        }
    }

    private var publishActionAllowed = false {
        didSet {
            if oldValue != publishActionAllowed {
                delegate?.context(self, didChangeActionAllowed: publishActionAllowed)
            }
        }
    }

    fileprivate var originalPostStatus: BasePost.Status?
    fileprivate var currentPostStatus: BasePost.Status?
    fileprivate var currentPublishDate: Date?
    fileprivate var userCanPublish: Bool
    private weak var delegate: PostEditorStateContextDelegate?

    fileprivate var hasContent = false {
        didSet {
            updatePublishActionAllowed()
        }
    }

    fileprivate var hasChanges = false {
        didSet {
            updatePublishActionAllowed()
        }
    }

    fileprivate var isBeingPublished = false {
        didSet {
            updatePublishActionAllowed()
        }
    }

    fileprivate(set) var isUploadingMedia = false {
        didSet {
            updatePublishActionAllowed()
        }
    }

    convenience init(post: AbstractPost,
                     delegate: PostEditorStateContextDelegate,
                     action: PostEditorAction? = nil) {
        var originalPostStatus: BasePost.Status? = nil

        let originalPost = post.original()
        if let postStatus = originalPost.status, originalPost.hasRemote() {
            originalPostStatus = postStatus
        }

        // Self-hosted non-Jetpack blogs have no capabilities, so we'll default
        // to showing Publish Now instead of Submit for Review.
        //
        let userCanPublish = post.blog.capabilities != nil ? post.blog.isPublishingPostsAllowed() : true

        self.init(originalPostStatus: originalPostStatus,
                  userCanPublish: userCanPublish,
                  publishDate: post.dateCreated,
                  delegate: delegate)

        if let action = action {
            self.action = action
        }
    }

    /// The default initializer
    ///
    /// - Parameters:
    ///   - originalPostStatus: If the post was already published (saved to the server) what is the status
    ///   - userCanPublish: Does the user have permission to publish posts or merely create drafts
    ///   - publishDate: The post publish date
    ///   - delegate: Delegate for listening to change in state for the editor
    ///
    required init(originalPostStatus: BasePost.Status? = nil, userCanPublish: Bool = true, publishDate: Date? = nil, delegate: PostEditorStateContextDelegate) {
        self.originalPostStatus = originalPostStatus
        self.currentPostStatus = originalPostStatus
        self.userCanPublish = userCanPublish
        self.currentPublishDate = publishDate
        self.delegate = delegate
        self.action = PostEditorStateContext.initialAction(for: originalPostStatus, publishDate: publishDate, userCanPublish: userCanPublish)
    }

    private static func initialAction(for originalPostStatus: BasePost.Status?, publishDate: Date?, userCanPublish: Bool) -> PostEditorAction {
        // We assume an initial status of draft if none is set
        let newPostStatus = originalPostStatus ?? .draft

        return action(for: originalPostStatus, newPostStatus: newPostStatus, publishDate: publishDate, userCanPublish: userCanPublish)
    }

    private static func action(
        for originalPostStatus: BasePost.Status?,
        newPostStatus: BasePost.Status,
        publishDate: Date?,
        userCanPublish: Bool
    ) -> PostEditorAction {
        guard RemoteFeatureFlag.syncPublishing.enabled() else {
            return _action(for: originalPostStatus, newPostStatus: newPostStatus, userCanPublish: userCanPublish)
        }

        func makePublishAction() -> PostEditorAction {
            guard userCanPublish else {
                return .submitForReview
            }
            guard let date = publishDate else {
                return .publish
            }
            return date > .now ? .schedule : .publish
        }

        let originalPostStatus = originalPostStatus ?? .draft
        switch originalPostStatus {
        case .draft:
            return makePublishAction()
        case .pending:
            if userCanPublish {
                // Let admin publish
                return makePublishAction()
            } else {
                // An contributor update
                return .update
            }
        case .publishPrivate, .publish, .scheduled:
            return .update
        case .trash, .deleted:
            return .update // Should not be editable
        }
    }

    /// - note: deprecated (kahu-offline-mode)
    private static func _action(
        for originalPostStatus: BasePost.Status?,
        newPostStatus: BasePost.Status,
        userCanPublish: Bool) -> PostEditorAction {
        let isNewOrDraft = { (status: BasePost.Status?) -> Bool in
            return status == nil || status == .draft
        }

        switch newPostStatus {
        case .draft where originalPostStatus == nil:
            return publishAction(userCanPublish: userCanPublish)
        case .draft:
            return .update
        case .pending:
            return .save
        case .publish where isNewOrDraft(originalPostStatus):
            return publishAction(userCanPublish: userCanPublish)
        case .publish:
            return .update
        case .publishPrivate where isNewOrDraft(originalPostStatus):
            return publishAction(userCanPublish: userCanPublish)
        case .publishPrivate:
            return .update
        case .scheduled where isNewOrDraft(originalPostStatus):
            return scheduleAction(userCanPublish: userCanPublish)
        case .scheduled:
            return .update
        case .deleted, .trash:
            // Deleted posts should really not be editable, but either way we'll try to handle it
            // gracefully by allowing a "Save" action, even it if failed.
            return .save
        }
    }

    private func action(for newPostStatus: BasePost.Status) -> PostEditorAction {
        return PostEditorStateContext.action(for: originalPostStatus, newPostStatus: newPostStatus, publishDate: currentPublishDate, userCanPublish: userCanPublish)
    }

    private static func publishAction(userCanPublish: Bool) -> PostEditorAction {
        if userCanPublish {
            return .publish
        } else {
            return .submitForReview
        }
    }

    private static func scheduleAction(userCanPublish: Bool) -> PostEditorAction {
        if userCanPublish {
            return .schedule
        } else {
            return .submitForReview
        }
    }

    /// Call when the post status has changed due to a remote operation
    ///
    func updated(postStatus: BasePost.Status) {
        currentPostStatus = postStatus
        action = action(for: postStatus)
    }

    /// Call when the publish date has changed (picked a future date) or nil if publish immediately selected
    ///
    func updated(publishDate: Date?) {
        currentPublishDate = publishDate
        if RemoteFeatureFlag.syncPublishing.enabled() {
            action = action(for: currentPostStatus ?? .draft)
        }
    }

    /// Call whenever the post content is not empty - title or content body
    ///
    func updated(hasContent: Bool) {
        self.hasContent = hasContent
    }

    /// Call whenever the post content was updated - title or content body
    ///
    func updated(hasChanges: Bool) {
        self.hasChanges = hasChanges
    }

    /// Call when the post is being published or has finished
    ///
    func updated(isBeingPublished: Bool) {
        self.isBeingPublished = isBeingPublished
    }

    /// Call whenever a Media Upload OP is started / stopped
    ///
    func update(isUploadingMedia: Bool) {
        self.isUploadingMedia = isUploadingMedia
    }

    /// Should the publish button be enabled given the current state
    ///
    var isPublishButtonEnabled: Bool {
        return publishActionAllowed
    }

    /// Returns appropriate Publish button text for the current action
    /// e.g. Publish, Schedule, Update, Save
    ///
    var publishButtonText: String {
        return action.publishActionLabel
    }

    /// Returns the WPAnalyticsStat enum to be tracked when this post is published
    ///
    var publishActionAnalyticsStat: WPAnalyticsStat {
        return action.publishActionAnalyticsStat
    }

    /// - note: deprecated (kahu-offline-mode)
    var isSecondaryPublishButtonShown: Bool {
        guard !RemoteFeatureFlag.syncPublishing.enabled() else {
            return false
        }

        guard hasContent else {
            return false
        }

        guard originalPostStatus != .publish
            && originalPostStatus != .publishPrivate
            && originalPostStatus != .scheduled else {
                return false
        }

        // Don't show Publish Now for a draft with a future date
        guard !(currentPostStatus == .draft && isFutureDated(currentPublishDate)) else {
            return false
        }

        return action.secondaryPublishAction != nil
    }

    /// - note: deprecated (kahu-offline-mode)
    var secondaryPublishButtonAction: PostEditorAction? {
        guard isSecondaryPublishButtonShown else {
            return nil
        }

        return action.secondaryPublishAction
    }

    /// - note: deprecated (kahu-offline-mode)
    var secondaryPublishButtonText: String? {
        guard isSecondaryPublishButtonShown else {
            return nil
        }

        return action.secondaryPublishAction?.publishActionLabel
    }

    /// - note: deprecated (kahu-offline-mode)
    var secondaryPublishActionAnalyticsStat: WPAnalyticsStat? {
        guard isSecondaryPublishButtonShown else {
            return nil
        }

        return action.secondaryPublishAction?.publishActionAnalyticsStat
    }

    /// Indicates whether the Publish Action should be allowed, or not
    ///
    private func updatePublishActionAllowed() {
        if RemoteFeatureFlag.syncPublishing.enabled() {
            switch action {
            case .schedule, .publish, .submitForReview:
                publishActionAllowed = hasContent
            case .update:
                publishActionAllowed = hasContent && hasChanges && !isBeingPublished
            case .save, .saveAsDraft, .continueFromHomepageEditing:
                assertionFailure("No longer used")
                break
            }
        } else {
            publishActionAllowed = hasContent && hasChanges && !isBeingPublished && (action.isAsync || !isUploadingMedia)
        }
    }
}

/// Helper methods for the entire state machine
///
fileprivate func isFutureDated(_ date: Date?) -> Bool {
    guard let date = date else {
        return false
    }

    let comparison = Calendar.current.compare(Date(), to: date, toGranularity: .minute)

    return comparison == .orderedAscending
}
