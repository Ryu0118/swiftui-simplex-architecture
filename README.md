# swiftui-simple-architecture
A Library of simple architectures with excellent performance that decouples state changes from SwiftUI's View

## Installation
```Swift
let package = Package(
    name: "YourProject",
    ...
    dependencies: [
        .package(url: https://github.com/Ryu0118/swiftui-simplex-architecture, branch: "main")
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: [
                .product(name: "SimplexArchitecture", package: "swiftui-simplex-architecture"),
            ]
        )
    ]
)
```

## Usage
#### Basic Usage
```Swift
@Reducer("MyView")
struct MyReducer {
    enum Action {
        case increment
        case decrement
    }
    func reduce(into state: inout State, action: Action) -> EffectTask<Self> {
        switch action {
        case .increment:
            state.counter += 1
            return .none
        case .decrement:
            state.counter -= 1
            return .none
        }
    }
}

@StoreBuilder(reducer: MyReducer())
struct MyView: View {
    @State var counter = 0

    var body: some View {
        VStack {
            Text("\(counter)")
            Button("+") {
                send(.increment)
            }
            Button("-") {
                send(.decrement)
            }
        }
    }
}
```

Use ReducerState if you want to keep the state only in the Reducer.
ReducerState is also effective to improve performance because the View is not updated even if the value is changed.

This is the example code
```Swift
@Reducer("MyView")
struct MyReducer {
    enum Action {
        case increment
        case decrement
    }

    struct ReducerState {
        var totalCalledCount = 0
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Self> {
        state.reducerState.totalCalledCount += 1
        switch action {
        case .increment:
            if state.reducerState.totalCalledCount < 10 {
                state.counter += 1
            }
            return .none
        case .decrement:
            state.counter -= 1
            return .none
        }
    }
}

@ManualStoreBuilder(reducer: MyReducer.self)
struct MyView: View {
    @State var counter = 0

    @State var store: Store<Self>

    init() {
        store = Store(reducer: MyReducer(), initialReducerState: MyReducer.ReducerState())
    }

    var body: some View {
        VStack {
            Text("\(counter)")
            Button("+") {
                send(.increment)
            }
            Button("-") {
                send(.decrement)
            }
        }
    }
}
```
If there are Actions that you do not want to expose to View, ReducerAction is effective.
This is the sample code:

```Swift
@Reducer("MyView")
struct MyReducer {
    enum Action {
        case login
    }

    enum ReducerAction {
        case loginResponse(TaskResult<Response>)
    }

    let authClient: AuthClient

    func reduce(into state: inout State, action: Action) -> EffectTask<Self> {
        switch action {
        case .login:
            return .run { [email = state.email, password = state.password] send in
                await send(
                    .loginResponse(
                        TaskResult { try await authClient.login(email, password) }
                    )
                )
            }
        }
    }

    func reduce(into state: inout State, action: ReducerAction) -> EffectTask<Self> {
        switch action {
        case let .loginResponse(result):
            ...
            return .none
        }
    }
}

@ManualStoreBuilder(reducer: MyReducer.self)
struct MyView: View {
    @State var email: String = ""
    @State var password: String = ""

    @State var store: Store<Self>

    init(authClient: AuthClient) {
        store = Store(reducer: MyReducer(authClient: authClient))
    }

    var body: some View {
        VStack {
            ...
            Button("Login") {
                send(.login)
            }
        }
        .onAppear {
            send(.loginResponse)) // ❌ Type 'MyReducer.Action' has no member 'loginResponse'
        }
    }
}
```
