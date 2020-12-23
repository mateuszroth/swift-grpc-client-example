import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack {
                Text("Echo message")
                TextField(
                    "Message",
                    text: viewStore.binding(
                        get: { $0.message }, send: AppAction.messageChanged)
                )
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .padding()
                .border(Color.gray, width: 1)
                .padding()
                
                Button(action: { viewStore.send(.echo) }, label: {
                    Text("Get echo")
                        .padding()
                })
                    .disabled(viewStore.isLoading)
                    .disabled(viewStore.isStreaming)
                
                Button(action: { viewStore.send(.toggleIsStreaming) }, label: {
                    Text("Toggle stream \(viewStore.isStreaming ? "(on)" : "(off)")")
                        .padding()
                })
                    .disabled(viewStore.isLoading)
                
                Text("Echo response:")
                Text(viewStore.receivedMessage)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: StoreContainer.appStore)
    }
}
