import GRPC
import Combine
import Foundation
import SwiftProtobuf

struct CounterActionRequestsFactory {
    var create: (_ actionId: String, _ clientId: Int64, _ name: String, _ initialValue: Int64) throws -> SyncV2ActionRequest
    var delete: (_ actionId: String, _ id: Int64) throws -> SyncV2ActionRequest
    var increment: (_ actionId: String, _ id: Int64) throws -> SyncV2ActionRequest
    var decrement: (_ actionId: String, _ id: Int64) throws -> SyncV2ActionRequest
}

extension CounterActionRequestsFactory {
    static func live() -> Self {
        
        func create(actionId: String, clientId: Int64, name: String, initialValue: Int64) throws -> SyncV2ActionRequest {
            var action = Sync_Entities_CreateCounter()
            action.clientSideID = clientId
            action.name = name
            action.initialValue = initialValue
            
            var request = SyncV2ClientMessage.ActionRequest()
            request.actionID = actionId
            request.content = try Google_Protobuf_Any.init(message: action)
            request.content.typeURL = request.content.typeURL.replacingOccurrences(of: "type.googleapis.com/", with: "")
            
            return request
        }
        
        func delete(actionId: String, id: Int64) throws -> SyncV2ActionRequest {
            var action = Sync_Entities_DeleteCounter()
            action.id = id
            
            var request = SyncV2ClientMessage.ActionRequest()
            request.actionID = actionId
            request.content = try Google_Protobuf_Any.init(message: action)
            request.content.typeURL = request.content.typeURL.replacingOccurrences(of: "type.googleapis.com/", with: "")
            
            return request
        }
        
        func increment(actionId: String, id: Int64) throws -> SyncV2ActionRequest {
            var action = Sync_Entities_IncrementCounter()
            action.id = id
            
            var request = SyncV2ClientMessage.ActionRequest()
            request.actionID = actionId
            request.content = try Google_Protobuf_Any.init(message: action)
            request.content.typeURL = request.content.typeURL.replacingOccurrences(of: "type.googleapis.com/", with: "")
            
            return request
        }
        
        func decrement(actionId: String, id: Int64) throws -> SyncV2ActionRequest {
            var action = Sync_Entities_DecrementCounter()
            action.id = id
            
            var request = SyncV2ClientMessage.ActionRequest()
            request.actionID = actionId
            request.content = try Google_Protobuf_Any.init(message: action)
            request.content.typeURL = request.content.typeURL.replacingOccurrences(of: "type.googleapis.com/", with: "")
            
            return request
        }

        return Self(
            create: create,
            delete: delete,
            increment: increment,
            decrement: decrement
        )
    }
}
