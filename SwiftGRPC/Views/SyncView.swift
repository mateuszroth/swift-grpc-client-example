import SwiftUI
import ComposableArchitecture

struct SyncView: View {
    let store: Store<SyncState, SyncAction>
    
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
                                viewStore.send(SyncAction.resetNew)
                            }, label: {
                                HStack {
                                    Image(systemName: "escape")
                                    Text("Close form")
                                }
                                
                            })
                            Button(action: {
                                viewStore.send(SyncAction.resetNew)
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

struct SyncView_Previews: PreviewProvider {
    static var previews: some View {
        SyncView(store: StoreContainer.appStore.scope(
            state: { $0.sync },
            action: AppAction.sync
        ))
    }
}
