import Foundation
import ComposableArchitecture
import Combine
import SwiftProtobuf

struct SyncV2State: Equatable {
    var counters: [Counter] = []
    var newName = ""
    var newValue: Int64 = 0
    var syncError: String?
    var showCreateForm = false
}

enum SyncV2Action {
    case resetState
    case syncResult(Result<SyncV2Response, Error>)
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

struct SyncV2Environment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let syncClient: SyncV2Client
    let counterActionRequestsFactory: CounterActionRequestsFactory
}

let syncV2Reducer = Reducer<SyncV2State, SyncV2Action, SyncV2Environment> { state, action, environment in
        switch action {
        case .resetState:
            state.syncError = nil
            return environment.syncClient.reset()
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(SyncV2Action.syncResult)

        case let .syncResult(.success(serverResponse)):
            switch serverResponse {
            case let .resetResponse(response):
                var counters: [Counter] = []
                response.entityEvents.entityEvents.forEach { entityEvent in
                    let entityId = entityEvent.entityMetadata.entityMetadata.id
                    switch entityEvent.content {
                    case let .create(entity):
                        let body = try? Sync_Entities_CounterBody(unpackingAny: entity.body)
                        counters.append(Counter(
                            id: entityId,
                            clientSideId: entity.clientSideID,
                            name: body?.name ?? "",
                            value: Int64(body?.value ?? 0)
                        ))
                    default:
                        break
                    }
                }
                state.counters = counters
                _ = environment.syncClient.entityEventAcknowledgement(response.entityEvents.batchID)
                    .receive(on: environment.mainQueue)

            case let .entityEventNotification(response):
                response.entityEvents.entityEvents.forEach { entityEvent in
                    let entityId = entityEvent.entityMetadata.entityMetadata.id
                    let typeId = entityEvent.entityMetadata.typeID

                    switch entityEvent.content {
                    case let .create(entity):
                        let body = try? Sync_Entities_CounterBody(unpackingAny: entity.body)
                        state.counters.append(Counter(
                            id: entityId,
                            clientSideId: entity.clientSideID,
                            name: body?.name ?? "",
                            value: body?.value ?? 0
                        ))
                        break
                    case let .delete(entity):
                        state.counters = state.counters.filter { $0.id != entityId }
                        break
                    case let .update(entity):
                        switch typeId {
                        case CounterTypeIds.counterBody.rawValue:
                            let body = try? Sync_Entities_CounterBody(unpackingAny: entity.body)
                            guard let bodyNotNil = body else {
                                break
                            }
                            if let row = state.counters.firstIndex(where: { $0.id == entityId }) {
                                state.counters[row].value = bodyNotNil.value
                                state.counters[row].name = bodyNotNil.name
                            }
                        default:
                            break
                        }
                        break
                    default:
                        break
                    }
                }
                _ = environment.syncClient.entityEventAcknowledgement(response.entityEvents.batchID)
                    .receive(on: environment.mainQueue)

            case let .actionResponse(response):
                response.entityEvents.entityEvents.forEach { entityEvent in
                    let entityId = entityEvent.entityMetadata.entityMetadata.id
                    let typeId = entityEvent.entityMetadata.typeID

                    switch entityEvent.content {
                    case let .create(entity):
                        let body = try? Sync_Entities_CounterBody(unpackingAny: entity.body)
                        if let row = state.counters.firstIndex(where: { $0.clientSideId == entity.clientSideID }) {
                            state.counters[row].id = entityId
                            state.counters[row].value = body?.value ?? 0
                            state.counters[row].name = body?.name ?? ""
                        }
                        break
                    case let .delete(entity):
                        state.counters = state.counters.filter { $0.id != entityId }
                    case let .update(entity):
                        switch typeId {
                        case CounterTypeIds.counterBody.rawValue:
                            let body = try? Sync_Entities_CounterBody(unpackingAny: entity.body)
                            guard let bodyNotNil = body else {
                                break
                            }
                            if let row = state.counters.firstIndex(where: { $0.id == entityId }) {
                                state.counters[row].value = bodyNotNil.value
                                state.counters[row].name = bodyNotNil.name
                            }
                        default:
                            break
                        }
                    default:
                        break
                    }
                }
                _ = environment.syncClient.entityEventAcknowledgement(response.entityEvents.batchID)
                    .receive(on: environment.mainQueue)

            default:
                return .none
            }
            return .none

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
            let actionRequest = try? environment.counterActionRequestsFactory.create(UUID().uuidString, counter.id, counter.name, counter.value)
            _ = environment.syncClient.action(actionRequest!)
                .receive(on: environment.mainQueue)
            return .none

        case .resetNew:
            state.newName = ""
            state.newValue = 0
            return .none

        case let .deleteCounter(index):
            let counter = state.counters[index]
            state.counters.remove(at: index)
            let actionRequest = try? environment.counterActionRequestsFactory.delete(UUID().uuidString, counter.id)
            _ = environment.syncClient.action(actionRequest!)
                .receive(on: environment.mainQueue)
            return .none

        case let .increment(counter):
            if let row = state.counters.firstIndex(where: { $0.id == counter.id }) {
                state.counters[row].value += 1
            }
            let actionRequest = try? environment.counterActionRequestsFactory.increment(UUID().uuidString, counter.id)
            _ = environment.syncClient.action(actionRequest!)
                .receive(on: environment.mainQueue)
            return .none

        case let .decrement(counter):
            if let row = state.counters.firstIndex(where: { $0.id == counter.id }) {
                state.counters[row].value -= 1
            }
            let actionRequest = try? environment.counterActionRequestsFactory.decrement(UUID().uuidString, counter.id)
            _ = environment.syncClient.action(actionRequest!)
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
