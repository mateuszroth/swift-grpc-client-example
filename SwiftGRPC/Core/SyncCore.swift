import Foundation
import ComposableArchitecture
import Combine

struct Counter: Identifiable, Equatable {
    var id: Int64
    var clientSideId: Int64
    var name: String
    var value: Int64
}

struct SyncState: Equatable {
    var counters: [Counter] = []
    var newName = ""
    var newValue: Int64 = 0
    var syncError: String?
    var showCreateForm = false
}

enum SyncAction {
    case resetState
    case syncResult(Result<SyncResponse, Error>)
    case updateName(String)
    case updateValue(Int64)
    case saveNew
    case resetNew
    case deleteCounter(Int)
    case increment(Counter)
    case decrement(Counter)
    case changeValue(Counter, Int64)
    case changeShowCreateForm(Bool)
}

struct SyncEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let syncClient: SyncClient
}

let syncReducer = Reducer<SyncState, SyncAction, SyncEnvironment> { state, action, environment in
        switch action {
        case .resetState:
            state.syncError = nil
            return environment.syncClient.reset()
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(SyncAction.syncResult)

        case let .syncResult(.success(serverResponse)):
            switch serverResponse {
            case let .resetResponse(response):
                var counters: [Counter] = []
                response.entityUpdates.entityUpdates.forEach { entityUpdate in
                    guard entityUpdate.create.hasBody else {
                        return
                    }
                    counters.append(Counter(
                        id: entityUpdate.id,
                        clientSideId: entityUpdate.create.clientSideID,
                        name: entityUpdate.create.body.counter.name,
                        value: Int64(entityUpdate.create.body.counter.value)
                    ))
                }
                state.counters = counters
                return .none
            
            case let .entityUpdateNotification(response):
                guard response.hasEntityUpdates else {
                    return .none
                }
                
                response.entityUpdates.entityUpdates.forEach { entityUpdate in
                    switch entityUpdate.content {
                    case let .create(entity):
                        state.counters.append(Counter(
                            id: entityUpdate.id,
                            clientSideId: entity.clientSideID,
                            name: entity.body.counter.name,
                            value: entity.body.counter.value
                        ))
                    case let .delete(entity):
                        state.counters = state.counters.filter { $0.id != entityUpdate.id }
                        // TODO: looks everything is correct, but the server doesn't propagate the event to other "listeners" and doesn't actually delete the counter on the server side
                    case let .update(entity):
                        if let row = state.counters.firstIndex(where: { $0.id == entityUpdate.id }) {
                            state.counters[row].value = entity.body.counter.value
                            state.counters[row].name = entity.body.counter.name
                        }
                    case .none:
                        break
                    }
                }
                
                return .none
                
            case let .actionResponse(response):
                guard response.hasEntityUpdates else {
                    return .none
                }
                
                response.entityUpdates.entityUpdates.forEach { entityUpdate in
                    switch entityUpdate.content {
                    case let .create(entity):
                        if let row = state.counters.firstIndex(where: { $0.clientSideId == entity.clientSideID }) {
                            state.counters[row].id = entityUpdate.id
                            state.counters[row].value = entity.body.counter.value
                            state.counters[row].name = entity.body.counter.name
                        }
                    case let .delete(entity):
                        state.counters = state.counters.filter { $0.id != entityUpdate.id }
                        // TODO: seems the server is broken - on delete returns false, but afterwards if you try to increment/decrement the counter, you will get another false every time despite it worked before deleting
                    case let .update(entity):
                        if let row = state.counters.firstIndex(where: { $0.id == entityUpdate.id }) {
                            state.counters[row].value = entity.body.counter.value
                            state.counters[row].name = entity.body.counter.name
                        }
                    case .none:
                        break
                    }
                }
                return .none
                
            default:
                return .none
            }
        case let .syncResult(.failure(error)):
            state.syncError = "ERROR: \(error)"
            return .none

        case let .updateName(name):
            state.newName = name
            return .none
        case let .updateValue(val):
            state.newValue = val
            return .none
        case .saveNew:
            let id = Date().millisecondsSince1970
            let counter = Counter(id: -id, clientSideId: -id, name: state.newName, value: state.newValue)
            state.newName = ""
            state.newValue = 0
            state.counters.append(counter)
            _ = environment.syncClient.createCounter(counter.id, counter.name, counter.value)
                .receive(on: environment.mainQueue)
            return .none
        case .resetNew:
            state.newName = ""
            state.newValue = 0
            return .none

        case let .deleteCounter(index):
            let counter = state.counters[index]
            state.counters.remove(at: index)
            _ = environment.syncClient.removeCounter(counter.id)
                .receive(on: environment.mainQueue)
            return .none

        case let .increment(counter):
            if let row = state.counters.firstIndex(where: { $0.id == counter.id }) {
                state.counters[row].value += 1
            }
            _ = environment.syncClient.incrementCounter(counter.id)
                .receive(on: environment.mainQueue)
            return .none
        case let .decrement(counter):
            if let row = state.counters.firstIndex(where: { $0.id == counter.id }) {
                state.counters[row].value -= 1
            }
            _ = environment.syncClient.decrementCounter(counter.id)
                .receive(on: environment.mainQueue)
            return .none

        case let .changeValue(counter, value):
            var updatedCounter = state.counters.first(where: { $0 == counter })
            updatedCounter?.value += value
            let index = state.counters.firstIndex(of: counter)
            guard let notNilIndex = index, let notNilUpdatedCounter = updatedCounter else {
                return .none
            }
            state.counters[notNilIndex] = notNilUpdatedCounter
            return .none
            
        case let .changeShowCreateForm(val):
            state.showCreateForm = val
            return .none
        }
}.debugActions()
