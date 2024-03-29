import Foundation
import Gridicons
import UIKit
import SwiftUI

struct SchedulingDatePickerConfiguration {
    var date: Date?
    var timeZone: TimeZone
    var updated: (Date?) -> Void
}

final class SchedulingDatePickerViewController: UIHostingController<SchedulingDatePickerView> {
    init(configuration: SchedulingDatePickerConfiguration) {
        super.init(rootView: SchedulingDatePickerView(configuration: configuration))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.title
}

struct SchedulingDatePickerView: View {
    @State var configuration: SchedulingDatePickerConfiguration

    var body: some View {
        List {
            HStack {
                Text(Strings.date)
                Spacer()

                Text(configuration.date.map(dateFormatter.string) ?? Strings.immediatelly)
                    .foregroundStyle(.secondary)

                if configuration.date != nil {
                    Button(action: {
                        configuration.date = nil
                        configuration.updated(nil)
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.secondary)
                    })
                }
            }
            .listRowSeparator(.hidden, edges: .top)

            DatePicker(Strings.title, selection: Binding(get: {
                configuration.date ?? Date()
            }, set: {
                configuration.date = $0
                configuration.updated($0)
            }))
            .environment(\.timeZone, configuration.timeZone)
            .labelsHidden()
            .tint(Color.primary)
            .datePickerStyle(.graphical)
        }
        .listStyle(.plain)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

extension SchedulingDatePickerViewController {
    static func make(viewModel: PublishSettingsViewModel, onDateUpdated: @escaping (Date?) -> Void) -> SchedulingDatePickerViewController {
        SchedulingDatePickerViewController(configuration: .init(
            date: viewModel.date,
            timeZone: viewModel.timeZone,
            updated: onDateUpdated
        ))
    }
}

private enum Strings {
    static let title = NSLocalizedString("publishDatePicker.title", value: "Publish Date", comment: "Post publish date picker")
    static let date = NSLocalizedString("publishDatePicker.date", value: "Date", comment: "Post publish date picker title for date cell")
    static let immediatelly = NSLocalizedString("publishDatePicker.immediately", value: "Immediately", comment: "The placeholder value for publish date picker")
}
