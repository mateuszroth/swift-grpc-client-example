import Foundation
import ComposableArchitecture
import Combine

struct Counter: Identifiable, Equatable {
    var id: String
    var name: String
    var value: Int
}

struct SyncState: Equatable {
    var counters: [Counter] = [
        Counter(id: "-1", name: "Local", value: 10),
        Counter(id: UUID().uuidString, name: "Server", value: 5)
    ]
    var newName = ""
    var newValue = 0
    var syncError: String?
}

enum SyncAction {
    case resetState
    case syncResult(Result<Sync_ServerMessage.OneOf_Content?, Error>)
    case updateName(String)
    case updateValue(Int)
    case saveNew
    case resetNew
    case deleteCounter(Int)
    case increment(Counter)
    case decrement(Counter)
    case changeValue(Counter, Int)
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
                        id: String(entityUpdate.create.clientSideID),
                        name: entityUpdate.create.body.counter.name,
                        value: Int(entityUpdate.create.body.counter.value)
                    ))
                }
                state.counters = counters
                return .none
                
            // TODO: more cases
                
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
            let counter = Counter(id: UUID().uuidString, name: state.newName, value: state.newValue)
            state.newName = ""
            state.newValue = 0
            state.counters.append(counter)
            return .none
        case .resetNew:
            state.newName = ""
            state.newValue = 0
            return .none
        case let .deleteCounter(index):
            state.counters.remove(at: index)
            return .none
        case let .increment(counter):
            return Effect(value: .changeValue(counter, 1))
        case let .decrement(counter):
            return Effect(value: .changeValue(counter, -1))
        case let .changeValue(counter, value):
            var updatedCounter = state.counters.first(where: { $0 == counter })
            updatedCounter?.value += value
            let index = state.counters.firstIndex(of: counter)
            guard let notNilIndex = index, let notNilUpdatedCounter = updatedCounter else {
                return .none
            }
            state.counters[notNilIndex] = notNilUpdatedCounter
            return .none
        }
}.debugActions()
