import SwiftUI
import ComposableArchitecture

struct SyncView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack {

            }
        }
    }
}

struct SyncView_Previews: PreviewProvider {
    static var previews: some View {
        SyncView(store: StoreContainer.appStore)
    }
}
