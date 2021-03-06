import Foundation
import ComposableArchitecture
import Combine

struct AppState: Equatable {
    var message: String = ""
    var receivedMessage: String = ""
    var isLoading: Bool = false
    var isStreaming: Bool = false
    var sync: SyncState
}

enum AppAction {
    case messageChanged(String)
    case echo
    case echoResult(Result<String, Error>)
    case toggleIsStreaming
    case echoStreamResult(Result<String, Error>)
    case sync(action: SyncAction)
}

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let echoClient: EchoClient
    let syncClient: SyncClient
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    syncReducer.pullback(
        state: \AppState.sync,
        action: /AppAction.sync,
        environment: {
            SyncEnvironment(
                mainQueue: $0.mainQueue,
                syncClient: $0.syncClient
            )}
    ),
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
        default:
            return .none
        }
    }
)

extension AppEnvironment {
    static let live = Self(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        echoClient: EchoClient.live(host: "0.0.0.0", port: 5005),
        syncClient: SyncClient.live(host: "0.0.0.0", port: 5005)
    )
}
