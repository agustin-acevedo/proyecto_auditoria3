import Foundation

extension AbstractPost {

    /// Returns the original post by navigating the entire list of revisions
    /// until it reaches the head.
    func original() -> AbstractPost {
        original?.original() ?? self
    }

    /// Returns `true` if the post was never uploaded to the remote and has
    /// not revisions that were marked for syncing.
    var isNewDraft: Bool {
        assert(isOriginal(), "Must be called on the original")
        return !hasRemote() && getLatestRevisionNeedingSync() == nil
    }

    // MARK: - Status

    /// - note: deprecated (kahu-offline-mode)
    @objc
    var statusTitle: String? {
        guard let status = self.status else {
            return nil
        }

        return AbstractPost.title(for: status)
    }

    /// - note: deprecated (kahu-offline-mode)
    @objc
    var remoteStatus: AbstractPostRemoteStatus {
        get {
            guard let remoteStatusNumber = remoteStatusNumber?.uintValue,
                let status = AbstractPostRemoteStatus(rawValue: remoteStatusNumber) else {
                    return .pushing
            }

            return status
        }

        set {
            remoteStatusNumber = NSNumber(value: newValue.rawValue)
        }
    }

    /// The status of self when we last received its data from the API.
    ///
    /// This is mainly used to identify which Post List tab should the post be shown in. For
    /// example, if a published post is transitioned to a draft but the app has not finished
    /// updating the server yet, we will continue to show the post in the Published list instead of
    /// the Drafts list. We believe this behavior is less confusing for the user.
    ///
    /// This is not meant to be up to date with the remote API. Eventually, this information will
    /// be outdated. For example, the user could have changed the status in the web while the device
    /// was offline. So we wouldn't recommend using this value aside from its original intention.
    ///
    /// - SeeAlso: PostService
    /// - SeeAlso: PostListFilter
    ///
    /// - note: deprecated (kahu-offline-mode)
    var statusAfterSync: Status? {
        get {
            return rawValue(forKey: "statusAfterSync")
        }
        set {
            setRawValue(newValue, forKey: "statusAfterSync")
        }
    }

    /// The string value of `statusAfterSync` based on `BasePost.Status`.
    ///
    /// This should only be used in Objective-C. For Swift, use `statusAfterSync`.
    ///
    /// - SeeAlso: statusAfterSync
    ///
    /// - note: deprecated (kahu-offline-mode)
    @objc(statusAfterSync)
    var statusAfterSyncString: String? {
        get {
            return statusAfterSync?.rawValue
        }
        set {
            statusAfterSync = newValue.flatMap { Status(rawValue: $0) }
        }
    }

    static func title(for status: Status) -> String {
        return title(forStatus: status.rawValue)
    }

    /// Returns the localized title for the specified status.  Status should be
    /// one of the `PostStatus...` constants.  If a matching title is not found
    /// the status is returned.
    ///
    /// - parameter status: The post status value
    ///
    /// - returns: The localized title for the specified status, or the status if a title was not found.
    ///
    @objc
    static func title(forStatus status: String) -> String {
        switch status {
        case PostStatusDraft:
            return NSLocalizedString("Draft", comment: "Name for the status of a draft post.")
        case PostStatusPending:
            return NSLocalizedString("Pending review", comment: "Name for the status of a post pending review.")
        case PostStatusPrivate:
            return NSLocalizedString("Private", comment: "Name for the status of a post that is marked private.")
        case PostStatusPublish:
            return NSLocalizedString("Published", comment: "Name for the status of a published post.")
        case PostStatusTrash:
            return NSLocalizedString("Trashed", comment: "Name for the status of a trashed post")
        case PostStatusScheduled:
            return NSLocalizedString("Scheduled", comment: "Name for the status of a scheduled post")
        default:
            return status
        }
    }

    // MARK: - Misc

    /// Represent the supported properties used to sort posts.
    ///
    enum SortField {
        case dateCreated
        case dateModified

        /// The keyPath to access the underlying property.
        ///
        var keyPath: String {
            switch self {
            case .dateCreated:
                return #keyPath(AbstractPost.date_created_gmt)
            case .dateModified:
                return #keyPath(AbstractPost.dateModified)
            }
        }
    }

    @objc func containsGutenbergBlocks() -> Bool {
        return content?.contains("<!-- wp:") ?? false
    }

    @objc func containsStoriesBlocks() -> Bool {
        return content?.contains("<!-- wp:jetpack/story") ?? false
    }

    var analyticsPostType: String? {
        switch self {
        case is Post:
            return "post"
        case is Page:
            return "page"
        default:
            return nil
        }
    }

    @objc override open func featuredImageURLForDisplay() -> URL? {
        return featuredImageURL
    }

    /// Returns true if the post has any media that needs manual intervention to be uploaded
    ///
    func hasPermanentFailedMedia() -> Bool {
        return media.first(where: { !$0.willAttemptToUploadLater() }) != nil
    }

    /// Returns the changes made in the current revision compared to the
    /// previous revision or the original post if there is only one revision.
    var changes: RemotePostUpdateParameters {
        guard let original else {
            return RemotePostUpdateParameters() // Empty
        }
        return RemotePostUpdateParameters.changes(from: original, to: self)
    }

    /// Returns all revisions of the post including the original one.
    var allRevisions: [AbstractPost] {
        var revisions: [AbstractPost] = [self]
        var current = self
        while let next = current.revision {
            revisions.append(next)
            current = next
        }
        return revisions

    }

    // TODO: Replace with a new flag
    /// - note: Work-in-progress (kahu-offline-mode)
    @objc var isSyncNeeded: Bool {
        get { confirmedChangesHash == AbstractPost.syncNeededKey }
        set { confirmedChangesHash = newValue ? AbstractPost.syncNeededKey : "" }
    }

    static let syncNeededKey = "sync-needed"

    /// Returns the latest saved revisions that needs to be synced with the server.
    /// Returns `nil` if there are no such revisions.
    func getLatestRevisionNeedingSync() -> AbstractPost? {
        assert(original == nil, "Must be called on an original revision")
        let revision = allRevisions.last(where: \.isSyncNeeded)
        guard revision != self else {
            return nil
        }
        return revision
    }

    /// Deletes all of the synced revisions until and including the `latest`
    /// one passed as a parameter.
    func deleteSyncedRevisions(until latest: AbstractPost) {
        assert(original == nil, "Must be called on an original revision")
        let tail = latest.revision

        var current = self
        while current !== latest, let next = current.revision {
            current.deleteRevision()
            current = next
        }

        if let tail {
            willChangeValue(forKey: "revision")
            setPrimitiveValue(tail, forKey: "revision")
            didChangeValue(forKey: "revision")
        }
    }
}
