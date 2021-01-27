import GRPC
import Combine
import Foundation
import SwiftProtobuf

typealias SyncV2Response = Sync_Protocol_ServerMessage.OneOf_Content?
typealias SyncV2ActionContent = SwiftProtobuf.Google_Protobuf_Any
typealias SyncV2ClientMessage = Sync_Protocol_ClientMessage
typealias SyncV2ActionRequest = SyncV2ClientMessage.ActionRequest

struct SyncV2Client {
    var reset: () -> AnyPublisher<SyncV2Response, Error>
    var resume: (_ lastProcessedEntityEventBatchID: String) -> AnyPublisher<SyncV2Response, Error>
    var action: (_ request: SyncV2ActionRequest) -> AnyPublisher<SyncV2Response, Error>
    var entityEventAcknowledgement: (_ batchID: String) -> AnyPublisher<SyncV2Response, Error>
}

extension SyncV2Client {
    static func live(host: String, port: Int) -> Self {
        let client: Sync_Protocol_SyncServiceClientProtocol
        var syncStreamCall: BidirectionalStreamingCall<Sync_Protocol_ClientMessage, Sync_Protocol_ServerMessage>?
        var isSyncStreaming = false
        let _syncStreamSubject = CurrentValueSubject<SyncV2Response, Error>(nil)
        var syncStreamSubject: AnyPublisher<SyncV2Response, Error> {
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
        
        func reset() -> AnyPublisher<SyncV2Response, Error> {
            setStreaming()
            
            var requestMessage = SyncV2ClientMessage()
            requestMessage.resetRequest = SyncV2ClientMessage.ResetRequest()
            _ = syncStreamCall?.sendMessage(requestMessage)
            
            return syncStreamSubject
        }
        
        func resume(lastProcessedEntityEventBatchID: String) -> AnyPublisher<SyncV2Response, Error> {
            setStreaming()
            
            var requestMessage = SyncV2ClientMessage()
            var resumeRequest = SyncV2ClientMessage.ResumeRequest()
            resumeRequest.lastProcessedEntityEventBatchID = lastProcessedEntityEventBatchID
            requestMessage.resumeRequest = resumeRequest
            _ = syncStreamCall?.sendMessage(requestMessage)
            
            return syncStreamSubject
        }
        
        func entityEventAcknowledgement(batchID: String) -> AnyPublisher<SyncV2Response, Error> {
            setStreaming()
            
            var requestMessage = SyncV2ClientMessage()
            var request = SyncV2ClientMessage.EntityEventAcknowledgement()
            request.batchID = batchID
            requestMessage.entityEventAcknowledgement = request
            _ = syncStreamCall?.sendMessage(requestMessage)
            
            return syncStreamSubject
        }
        
        func action(request: SyncV2ActionRequest) -> AnyPublisher<SyncV2Response, Error> {
            setStreaming()
            
            var requestMessage = SyncV2ClientMessage()
            requestMessage.actionRequest = request
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
        
        client = Sync_Protocol_SyncServiceClient(channel: channel, defaultCallOptions: callOptions)
        
        return Self(
            reset: reset,
            resume: resume,
            action: action,
            entityEventAcknowledgement: entityEventAcknowledgement
        )
    }
}
