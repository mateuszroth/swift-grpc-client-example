import SwiftUI
import ComposableArchitecture

struct AddNewCounterView: View {
    let store: Store<SyncState, SyncAction>
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            WithViewStore(self.store) { viewStore in
                Group {
                    Button(action: {
                        viewStore.send(SyncAction.resetNew)
                    }, label: {
                        Text("Clear")
                    })
                    Section {
                        TextField("Counter name", text: viewStore.binding(
                                    get: { $0.newName }, send: SyncAction.updateName))
                        Stepper(
                            value: viewStore.binding(
                                get: { $0.newValue }, send: SyncAction.updateValue),
                            in: -10...10,
                            step: 1
                        ) {
                            Text("Current: \(viewStore.newValue)")
                        }
                    }
                    Button(action: {
                        viewStore.send(SyncAction.saveNew)
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Save")
                    })
                }
            }
        }
            .navigationTitle("Add a new counter")
            .navigationBarTitleDisplayMode(.inline) // or .large
    }
}

struct SyncView: View {
    let store: Store<SyncState, SyncAction>
    @State var isModal: Bool = false
    @State var name = ""
    
    var body: some View {
        WithViewStore(self.store) { viewStore in
            return NavigationView {
                List {
                    ForEach(viewStore.counters) { counter in
                        HStack {
                            Text("\(counter.name): ")
                            Stepper(
                                onIncrement: { viewStore.send(.increment(counter))
                                },
                                onDecrement: {
                                    viewStore.send(.decrement(counter))
                                }
                            ) {
                                Text("\(counter.value)")
                                    .fontWeight(.bold)
                            }
                        }
                        .padding()
                    }
                    .onDelete { index in
                        guard let ind = index.first else {
                            return
                        }
                        viewStore.send(.deleteCounter(ind))
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        // there might be a bug within NavigationLink https://stackoverflow.com/questions/57946197/navigationlink-on-swiftui-pushes-view-twice
                        NavigationLink(destination: AddNewCounterView(store: store), isActive: $isModal) {
                                Image(systemName: "plus")
                        }
                    }
                }
            }.onAppear {
                viewStore.send(.resetState)
            }
        }
    }
}

struct SyncView_Previews: PreviewProvider {
    static var previews: some View {
        SyncView(store: StoreContainer.appStore.scope(
            state: { $0.sync },
            action: AppAction.sync
        ))
    }
}
