import Foundation

/// A struct that holds all remote config parameters.
/// This is where all remote config parameters should be defined.
struct RemoteConfig {

    // MARK: Private Variables

    private var store: RemoteConfigStore

    // MARK: Initializer

    init(store: RemoteConfigStore = RemoteConfigStore()) {
        self.store = store
    }

    // MARK: Remote Config Parameters

    var jetpackDeadline: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "jp-deadline", defaultValue: "2022-12-31", store: store) // TODO: Revert this
    }

    var phaseTwoBlogPostUrl: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "phase-two-blog-post", defaultValue: "https://jetpack.com/mobile", store: store) // TODO: Revert this
    }

    var phaseThreeBlogPostUrl: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "phase-three-blog-post", defaultValue: "https://jetpack.com/mobile", store: store) // TODO: Revert this
    }

    var phaseFourBlogPostUrl: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "phase-four-blog-post", defaultValue: nil, store: store)
    }

    var phaseNewUsersBlogPostUrl: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "phase-new-users-blog-post", defaultValue: nil, store: store)
    }

    var phaseSelfHostedBlogPostUrl: RemoteConfigParameter<String> {
        RemoteConfigParameter<String>(key: "phase-self-hosted-blog-post", defaultValue: nil, store: store)
    }
}
