import SwiftUI
import ComposableArchitecture

struct StoreContainer {
    static let appStore: Store<AppState, AppAction> = Store(
        initialState: AppState(sync: SyncState()),
        reducer: appReducer,
        environment: AppEnvironment.live
    )
}

@main
struct SwiftGRPCApp: App {
    var body: some Scene {
        WindowGroup {
            AppNavigationView(store: StoreContainer.appStore)
        }
    }
}
