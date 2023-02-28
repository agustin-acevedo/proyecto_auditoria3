import XCTest
@testable import WordPress

final class BlazeWebViewModelTests: CoreDataTestCase {

    // MARK: Private Variables

    private var remoteConfigStore = RemoteConfigStoreMock()
    private var blog: Blog!
    private static let blogURL  = "test.blog.com"

    // MARK: Setup

    override func setUp() {
        super.setUp()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        blog = BlogBuilder(mainContext).with(url: Self.blogURL).build()
        remoteConfigStore.blazeNonDismissibleSteps = ["step-4"]
        remoteConfigStore.blazeFlowCompletedStep = "step-5"
    }

    // MARK: Tests

    func testPostsListStep() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }

    func testPostsListStepWithPostsPath() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }

    func testCampaignsStep() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/campaigns?source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "campaigns-list")
    }

    func testDefaultWidgetStep() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?blazepress-widget=post-2&source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "step-1")
    }

    func testDefaultWidgetStepWithPostsPath() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2&source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "step-1")
    }

    func testExtractStepFromFragment() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?blazepress-widget=post-2&source=menu_item#step-2"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "step-2")
    }

    func testExtractStepFromFragmentPostsPath() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2&source=menu_item#step-3"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "step-3")
    }

    func testPostsListStepWithoutQuery() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }

    func testPostsListStepWithPostsPathWithoutQuery() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }

    func testCampaignsStepWithoutQuery() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/campaigns"))
        let request = URLRequest(url: url)

        // When
        let policy = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertEqual(policy, .allow)
        XCTAssertEqual(viewModel.currentStep, "campaigns-list")
    }

    func testInitialStep() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)

        // Then
        XCTAssertEqual(viewModel.currentStep, "unspecified")
    }

    func testCurrentStepMaintainedIfExtractionFails() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let postsListURL = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?source=menu_item"))
        let postsListRequest = URLRequest(url: postsListURL)
        let invalidURL = try XCTUnwrap(URL(string: "https://test.com/test?example=test"))
        let invalidRequest = URLRequest(url: invalidURL)

        // When
        let _ = viewModel.shouldNavigate(request: postsListRequest)

        // Then
        XCTAssertEqual(viewModel.currentStep, "posts-list")

        // When
        let _ = viewModel.shouldNavigate(request: invalidRequest)
        XCTAssertEqual(viewModel.currentStep, "posts-list")
    }

    func testCallingShouldNavigateReloadsTheNavBar() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com?source=menu_item"))
        let request = URLRequest(url: url)

        // When
        let _ = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertTrue(view.reloadNavBarCalled)
    }

    func testCallingDismissTappedDismissesTheView() {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)

        // When
        viewModel.dismissTapped()

        // Then
        XCTAssertTrue(view.dismissViewCalled)
    }

    func testCallingStartBlazeSiteFlowLoadsTheView() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view)

        // When
        viewModel.startBlazeFlow()

        // Then
        XCTAssertTrue(view.loadCalled)
        XCTAssertEqual(view.requestLoaded?.url?.absoluteString, "https://wordpress.com/advertising/test.blog.com?source=menu_item")
    }

    func testCallingStartBlazePostFlowLoadsTheView() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: 1, view: view)

        // When
        viewModel.startBlazeFlow()

        // Then
        XCTAssertTrue(view.loadCalled)
        XCTAssertEqual(view.requestLoaded?.url?.absoluteString, "https://wordpress.com/advertising/test.blog.com?blazepress-widget=post-1&source=menu_item")
    }

    func testIsCurrentStepDismissible() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, remoteConfigStore: remoteConfigStore)

        // When
        var url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2#step-1"))
        var request = URLRequest(url: url)
        let _ = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertTrue(viewModel.isCurrentStepDismissible())

        // When
        url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2#step-4"))
        request = URLRequest(url: url)
        let _ = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertFalse(viewModel.isCurrentStepDismissible())

        // When
        url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2#step-5"))
        request = URLRequest(url: url)
        let _ = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertTrue(viewModel.isCurrentStepDismissible())
    }

    func testIsFlowCompleted() throws {
        // Given
        let view = BlazeWebViewMock()
        let viewModel = BlazeWebViewModel(source: .menuItem, blog: blog, postID: nil, view: view, remoteConfigStore: remoteConfigStore)

        // When
        var url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2#step-1"))
        var request = URLRequest(url: url)
        let _ = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertFalse(viewModel.isFlowCompleted)

        // When
        url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2#step-5"))
        request = URLRequest(url: url)
        let _ = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertTrue(viewModel.isFlowCompleted)

        // When
        url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/test.blog.com/posts?blazepress-widget=post-2#step-1"))
        request = URLRequest(url: url)
        let _ = viewModel.shouldNavigate(request: request)

        // Then
        XCTAssertFalse(viewModel.isFlowCompleted)
    }
}

private class BlazeWebViewMock: BlazeWebView {

    var loadCalled = false
    var requestLoaded: URLRequest?
    var reloadNavBarCalled = false
    var dismissViewCalled = false

    func load(request: URLRequest) {
        loadCalled = true
        requestLoaded = request
    }

    func reloadNavBar() {
        reloadNavBarCalled = true
    }

    func dismissView() {
        dismissViewCalled = true
    }

    var cookieJar: WordPress.CookieJar = MockCookieJar()
}
