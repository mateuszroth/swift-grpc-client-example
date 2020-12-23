import SwiftUI
import ComposableArchitecture

struct Counter: Identifiable {
    var id: String
    var name: String
    var value: Int
}

struct CounterRow: View {
    let counter: Counter
    
    var body: some View {
        HStack {
            Image(systemName: "delete.right")
                .padding()
            Text(counter.name)
            Spacer()
            Group {
                Text("\(counter.value)")
                    .fontWeight(.bold)
                Image(systemName: "plus.circle")
                    .padding()
                Image(systemName: "minus.circle")
            }
        }
        .padding()
    }
}

struct SyncView: View {
    let store: Store<AppState, AppAction>
    @State var isModal: Bool = false
    @State var name = ""
    @State var value = 0
    @State var counters: [Counter] = [
        Counter(id: "-1", name: "Local", value: 10),
        Counter(id: UUID().uuidString, name: "Server", value: 5)
    ]

    var modal: some View {
        WithViewStore(self.store) { viewStore in
            Form {
                Section {
                    Text("Add a new counter").font(.headline)
                    TextField("Counter name", text: $name)
                    Stepper(value: $value, in: 0...10, label: { Text("Value") })
                    Text("Current value: \(value)")
                    Button("Save") {}
                }
            }
        }
    }
    
    var body: some View {
        WithViewStore(self.store) { viewStore in
            NavigationView {
                Group {
                    List {
                        ForEach(counters, id: \.id) { counter in
                            CounterRow(counter: counter)
                        }
                    }
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    self.isModal = true
                                } label: {
                                    Image(systemName: "plus")
                                }.sheet(isPresented: $isModal, content: {
                                    self.modal
                                })
                            }

                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    self.isModal = true
                                } label: {
                                    Image(systemName: "plus")
                                }.sheet(isPresented: $isModal, content: {
                                    self.modal
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
        SyncView(store: StoreContainer.appStore)
    }
}
