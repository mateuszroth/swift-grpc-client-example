import SwiftUI
import ComposableArchitecture

struct SyncV2View: View {
    let store: Store<SyncV2State, SyncV2Action>
    
    var body: some View {
        return WithViewStore(self.store) { viewStore in
            VStack {
                if !viewStore.showCreateForm {
                    Group {
                        Button(action: {
                            viewStore.send(.changeShowCreateForm(true))
                        }, label: {
                            Text("Add a new counter")
                                .padding()
                        })
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
                    }
                }
                if viewStore.showCreateForm {
                    Form {
                        Group {
                            Button(action: {
                                viewStore.send(.changeShowCreateForm(false))
                                viewStore.send(SyncV2Action.resetNew)
                            }, label: {
                                HStack {
                                    Image(systemName: "escape")
                                    Text("Close form")
                                }
                                
                            })
                            Button(action: {
                                viewStore.send(SyncV2Action.resetNew)
                            }, label: {
                                HStack {
                                    Image(systemName: "delete.left.fill")
                                        .foregroundColor(.red)
                                    Text("Clear form")
                                        .foregroundColor(.red)
                                }
                            })
                            Section {
                                TextField("Counter name", text: viewStore.binding(
                                            get: { $0.newName }, send: SyncV2Action.updateName))
                                Stepper(
                                    value: viewStore.binding(
                                        get: { $0.newValue }, send: SyncV2Action.updateValue),
                                    in: -10...10,
                                    step: 1
                                ) {
                                    Text("Current: \(viewStore.newValue)")
                                }
                            }
                            Button(action: {
                                viewStore.send(SyncV2Action.saveNew)
                                viewStore.send(.changeShowCreateForm(false))
                            }, label: {
                                Text("Save")
                            })
                        }
                    }
                }
            }
        }
    }
}

struct SyncV2View_Previews: PreviewProvider {
    static var previews: some View {
        SyncV2View(store: StoreContainer.appStore.scope(
            state: { $0.syncV2 },
            action: AppAction.syncV2
        ))
    }
}
