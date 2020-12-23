import Foundation
import ComposableArchitecture
import Combine

struct AppState: Equatable {
    var message: String = ""
    var receivedMessage: String = ""
    var isLoading: Bool = false
    var isStreaming: Bool = false
}

enum AppAction {
    case messageChanged(String)
    case echo
    case echoResult(Result<String, Error>)
    case toggleIsStreaming
    case echoStreamResult(Result<String, Error>)
}

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let echoClient: EchoClient
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
        switch action {
        case let .messageChanged(message):
            state.message = message
            state.receivedMessage = ""
            if state.isStreaming {
                return environment.echoClient.echoStream(message)
                    .receive(on: environment.mainQueue)
                    .catchToEffect()
                    .map(AppAction.echoStreamResult)
            } else {
                return .none
            }
        case .echo:
            let message = state.message
            state.message = ""
            state.receivedMessage = ""
            state.isLoading = true
            return environment.echoClient.echo(message)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(AppAction.echoResult)
        case let .echoResult(.success(message)):
            state.receivedMessage = message
            state.isLoading = false
            return .none
        case let .echoResult(.failure(error)):
            state.receivedMessage = "ERROR: \(error)"
            state.isLoading = false
            return .none
        case let .echoStreamResult(.success(message)):
            state.receivedMessage = message
            return .none
        case let .echoStreamResult(.failure(error)):
            state.receivedMessage = "ERROR: \(error)"
            return .none
        case .toggleIsStreaming:
            state.isStreaming = !state.isStreaming
            return .none
        }
    }
)

extension AppEnvironment {
    static let live = Self(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        echoClient: EchoClient.live(host: "0.0.0.0", port: 5005)
    )
}
