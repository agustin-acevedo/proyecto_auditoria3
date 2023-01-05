import Foundation

@objc
extension PeopleViewController {
    static func withJPBannerForBlog(_ blog: Blog) -> UIViewController? {
        guard let peopleViewVC = PeopleViewController.controllerWithBlog(blog) else {
            return nil
        }
        guard JetpackBrandingCoordinator.shouldShowBannerForJetpackDependentFeatures() else {
            return peopleViewVC
        }
        return JetpackBannerWrapperViewController(childVC: peopleViewVC, screen: .people)
    }
}

extension PeopleViewController: JPScrollViewDelegate {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        processJetpackBannerVisibility(scrollView)
    }
}
