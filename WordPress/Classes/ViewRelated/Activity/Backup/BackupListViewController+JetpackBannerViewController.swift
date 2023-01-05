import Foundation

@objc
extension BackupListViewController {
    static func withJPBannerForBlog(_ blog: Blog) -> UIViewController? {
        guard let backupListVC = BackupListViewController(blog: blog) else {
            return nil
        }
        return JetpackBannerWrapperViewController(childVC: backupListVC, screen: .backup)
    }
}

extension BackupListViewController: JPScrollViewDelegate {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        processJetpackBannerVisibility(scrollView)
    }
}
