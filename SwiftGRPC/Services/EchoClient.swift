import GRPC
import Combine

struct EchoClient {
    var echo: (_ message: String) -> AnyPublisher<String, Error>
    var echoStream: (_ message: String) -> AnyPublisher<String, Error>
}

extension EchoClient {
    static func live(host: String, port: Int) -> Self {
        var client: Echo_EchoServiceClientProtocol
        var echoStreamCall: BidirectionalStreamingCall<Echo_EchoMessage, Echo_EchoMessage>?
        var isEchoStreaming = false
        let _echoStreamSubject = CurrentValueSubject<String, Error>("")
        var echoStreamSubject: AnyPublisher<String, Error> {
            _echoStreamSubject.eraseToAnyPublisher()
        }
        
        func echo(message: String) -> AnyPublisher<String, Error> {
            var requestMessage = Echo_EchoMessage()
            requestMessage.content = message
            
            return Future<Echo_EchoMessage, Error> { promise in
                let result = client.echo(requestMessage)
                result.response.whenComplete { res in
                    promise(res)
                }
            }
                .map { val in
                    val.content
                }
                .eraseToAnyPublisher()
        }
        
        func echoStream(message: String) -> AnyPublisher<String, Error> {
            if !isEchoStreaming {
                echoStreamCall = client.echoStream { response in
                    _echoStreamSubject.send(response.content)
                }
            }
            isEchoStreaming = true
            
            var requestMessage = Echo_EchoMessage()
            requestMessage.content = message
            _ = echoStreamCall?.sendMessage(requestMessage)
            
            return echoStreamSubject
        }
        
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        let channel = ClientConnection
            .insecure(group: group)
            .connect(host: host, port: port)

        client = Echo_EchoServiceClient(channel: channel)

        return Self(
            echo: echo,
            echoStream: echoStream
        )
    }
}
