import GRPC
import Combine
import Foundation

typealias SyncResponse = Sync_ServerMessage.OneOf_Content?

struct SyncClient {
    var reset: () -> AnyPublisher<SyncResponse, Error>
    var incrementCounter: (_ id: Int64) -> AnyPublisher<SyncResponse, Error>
    var decrementCounter: (_ id: Int64) -> AnyPublisher<SyncResponse, Error>
    var renameCounter: (_ id: Int64, _ name: String) -> AnyPublisher<SyncResponse, Error>
    var changeCounterValue: (_ id: Int64, _ value: Int64) -> AnyPublisher<SyncResponse, Error>
    var removeCounter: (_ id: Int64) -> AnyPublisher<SyncResponse, Error>
    var createCounter: (_ id: Int64, _ name: String, _ value: Int64) -> AnyPublisher<SyncResponse, Error>
}

extension SyncClient {
    static func live(host: String, port: Int) -> Self {
        let client: Sync_SyncServiceClientProtocol
        var syncStreamCall: BidirectionalStreamingCall<Sync_ClientMessage, Sync_ServerMessage>?
        var isSyncStreaming = false
        let _syncStreamSubject = CurrentValueSubject<SyncResponse, Error>(nil)
        var syncStreamSubject: AnyPublisher<SyncResponse, Error> {
            _syncStreamSubject.eraseToAnyPublisher()
        }
        
        func setStreaming() {
            if !isSyncStreaming {
                syncStreamCall = client.synchronize { response in
                    _syncStreamSubject.send(response.content)
                }
            }
            isSyncStreaming = true
        }
        
        func reset() -> AnyPublisher<SyncResponse, Error> {
            setStreaming()
            
            var requestMessage = Sync_ClientMessage()
            requestMessage.resetRequest = Sync_ClientMessage.ResetRequest()
            _ = syncStreamCall?.sendMessage(requestMessage)
            
            return syncStreamSubject
        }
        
        func incrementCounter(id: Int64) -> AnyPublisher<SyncResponse, Error> {
            setStreaming()
            
            var requestMessage = Sync_ClientMessage()
            requestMessage.actionRequest = Sync_ClientMessage.ActionRequest()
            requestMessage.actionRequest.actionID = UUID().uuidString
            requestMessage.actionRequest.increment.id = id
            _ = syncStreamCall?.sendMessage(requestMessage)
            
            return syncStreamSubject
        }
        
        func decrementCounter(id: Int64) -> AnyPublisher<SyncResponse, Error> {
            setStreaming()
            
            var requestMessage = Sync_ClientMessage()
            requestMessage.actionRequest = Sync_ClientMessage.ActionRequest()
            requestMessage.actionRequest.actionID = UUID().uuidString
            requestMessage.actionRequest.decrement.id = id
            _ = syncStreamCall?.sendMessage(requestMessage)
            
            return syncStreamSubject
        }
        
        func renameCounter(id: Int64, name: String) -> AnyPublisher<SyncResponse, Error> {
            setStreaming()
            
            var requestMessage = Sync_ClientMessage()
            requestMessage.actionRequest = Sync_ClientMessage.ActionRequest()
            requestMessage.actionRequest.actionID = UUID().uuidString
            requestMessage.actionRequest.rename.id = id
            requestMessage.actionRequest.rename.newName = name
            _ = syncStreamCall?.sendMessage(requestMessage)
            
            return syncStreamSubject
        }
        
        func changeCounterValue(id: Int64, value: Int64) -> AnyPublisher<SyncResponse, Error> {
            setStreaming()
            
            var requestMessage = Sync_ClientMessage()
            requestMessage.actionRequest = Sync_ClientMessage.ActionRequest()
            requestMessage.actionRequest.actionID = UUID().uuidString
            requestMessage.actionRequest.setValue.id = id
            requestMessage.actionRequest.setValue.value = value
            _ = syncStreamCall?.sendMessage(requestMessage)
            
            return syncStreamSubject
        }
        
        func removeCounter(id: Int64) -> AnyPublisher<SyncResponse, Error> {
            setStreaming()
            
            var requestMessage = Sync_ClientMessage()
            requestMessage.actionRequest = Sync_ClientMessage.ActionRequest()
            requestMessage.actionRequest.actionID = UUID().uuidString
            requestMessage.actionRequest.delete.id = id
            _ = syncStreamCall?.sendMessage(requestMessage)
            
            return syncStreamSubject
        }
        
        func createCounter(id: Int64, name: String, value: Int64) -> AnyPublisher<SyncResponse, Error> {
            setStreaming()
            
            var requestMessage = Sync_ClientMessage()
            requestMessage.actionRequest = Sync_ClientMessage.ActionRequest()
            requestMessage.actionRequest.actionID = UUID().uuidString
            requestMessage.actionRequest.create.clientSideID = id
            requestMessage.actionRequest.create.name = name
            requestMessage.actionRequest.create.initialValue = value
            _ = syncStreamCall?.sendMessage(requestMessage)
            
            return syncStreamSubject
        }
        
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        let channel = ClientConnection
            .insecure(group: group)
            .connect(host: host, port: port)
        
        var callOptions = CallOptions()
        callOptions.customMetadata.add(name: "userId", value: "user1")
        callOptions.customMetadata.add(name: "deviceId", value: "device1")
        
        client = Sync_SyncServiceClient(channel: channel, defaultCallOptions: callOptions)
        
        return Self(
            reset: reset,
            incrementCounter: incrementCounter,
            decrementCounter: decrementCounter,
            renameCounter: renameCounter,
            changeCounterValue: changeCounterValue,
            removeCounter: removeCounter,
            createCounter: createCounter
        )
    }
}
