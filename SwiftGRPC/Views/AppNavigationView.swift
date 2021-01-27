import SwiftUI
import ComposableArchitecture

struct AppNavigationView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            TabView {
                ContentView(store: store)
                    .tabItem {
                        Image(systemName: "message")
                        Text("Echo")
                    }
                
                SyncView(store: store.scope(state: { $0.sync }, action: AppAction.sync))
                    .tabItem {
                        Image(systemName: "arrow.clockwise.icloud")
                        Text("Sync")
                    }
                
                SyncV2View(store: store.scope(state: { $0.syncV2 }, action: AppAction.syncV2))
                    .tabItem {
                        Image(systemName: "arrow.clockwise.icloud")
                        Text("Sync V2")
                    }
            }
            .onAppear {
                viewStore.send(.syncV2(action: .resetState))
            }
        }
    }
}

struct AppNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        AppNavigationView(store: StoreContainer.appStore)
    }
}
