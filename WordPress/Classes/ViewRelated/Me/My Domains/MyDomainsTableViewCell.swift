import UIKit
import SwiftUI

final class MyDomainsTableViewCell: UITableViewCell {

    private var hostingController: UIHostingController<DomainListCard>?

    func update(with viewModel: ViewModel, parent: UIViewController) {
        let content = DomainListCard(viewModel: viewModel)

        if let hostingController {
            hostingController.rootView = content
        } else {
            let hostingController = UIHostingController(rootView: content)
            hostingController.view.backgroundColor = .clear
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            hostingController.willMove(toParent: parent)
            self.contentView.addSubview(hostingController.view)
            self.contentView.pinSubviewToAllEdges(hostingController.view)
            parent.addChild(hostingController)
            hostingController.didMove(toParent: parent)
            self.hostingController = hostingController
        }

        self.hostingController?.view.layoutIfNeeded()
    }

    typealias ViewModel = DomainListCard.ViewModel
}
