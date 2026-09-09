import SwiftUI
import LeeoKit

struct StickyPresenterSupportView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    LeeoSupportSection<StickyPresenterSpec>()
                } header: {
                    Text(L("settings.support"))
                }
            }
            .navigationTitle(L("settings.title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}
