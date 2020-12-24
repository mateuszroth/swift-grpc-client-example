import GRPC
import Combine

struct SyncClient {
    var reset: () -> AnyPublisher<Sync_ServerMessage.OneOf_Content?, Error>
}

extension SyncClient {
    static func live(host: String, port: Int) -> Self {
        let client: Sync_SyncServiceClientProtocol
        var syncStreamCall: BidirectionalStreamingCall<Sync_ClientMessage, Sync_ServerMessage>?
        var isSyncStreaming = false
        let _syncStreamSubject = CurrentValueSubject<Sync_ServerMessage.OneOf_Content?, Error>(nil)
        var syncStreamSubject: AnyPublisher<Sync_ServerMessage.OneOf_Content?, Error> {
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
        
        func reset() -> AnyPublisher<Sync_ServerMessage.OneOf_Content?, Error> {
            setStreaming()
            
            var requestMessage = Sync_ClientMessage()
            requestMessage.resetRequest = Sync_ClientMessage.ResetRequest()
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
            reset: reset
        )
    }
}
