import SwiftUI

struct ContentView: View {
    @StateObject var vm = AppClipViewModel()

    var body: some View {
        VStack {
            switch vm.appState {
            case .marketing:
                Text("Marketing view")
            case .photosPicker(let payload):
                MediaUploadView(vm: PickerModel(payload: payload))
            }

        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb, perform: { userActivity in
            // grab the payload from the URL that loaded the App Clip
            guard let url = userActivity.webpageURL else {
                return
            }
            vm.processUrl(url)
        })
        .padding()
    }
}
