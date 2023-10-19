<div align="center">  

  # Simplex Architecture

  <img width="450" alt="image" src="https://github.com/Ryu0118/swiftui-simplex-architecture/assets/87907656/69d1e19d-e011-4f13-ba26-39551205ed10">
  
  #### A Library of simple architectures that decouples state changes from SwiftUI's View.
  
  ![Language:Swift](https://img.shields.io/static/v1?label=Language&message=Swift&color=orange&style=flat-square)
  ![License:MIT](https://img.shields.io/static/v1?label=License&message=MIT&color=blue&style=flat-square)
  [![Latest Release](https://img.shields.io/github/v/release/Ryu0118/swiftui-simplex-architecture?style=flat-square)](https://github.com/Ryu0118/swiftui-simplex-architecture/releases/latest)
  [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRyu0118%2Fswiftui-simplex-architecture%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Ryu0118/swiftui-simplex-architecture)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRyu0118%2Fswiftui-simplex-architecture%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Ryu0118/swiftui-simplex-architecture)
  [![Twitter](https://img.shields.io/twitter/follow/ryu_hu03?style=social)](https://twitter.com/ryu_hu03)
</div>

This library is inspired by TCA ([swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture)), which allows you to decouple the state change logic from the SwiftUI's View and ObservableObject and confine it within the Reducer.

In TCA, integrating child domains into parent domains resulted in higher computational costs, especially at the leaf nodes of the app. Our library addresses this by avoiding the integration of child domains into parent domains, eliminating unnecessary computational overhead. To share values or logic with deeply nested views, we leverage SwiftUI's EnvironmentObject property wrapper. This allows you to seamlessly write logic or state that can be accessed throughout the app. Moreover, our library simplifies the app-building process. You no longer need to remember various TCA modifiers or custom views like ForEachStore, IfLetStore, SwitchStore, sheet(store:), and so on.

## Installation
```Swift
let package = Package(
    name: "YourProject",
    ...
    dependencies: [
        .package(url: "https://github.com/Ryu0118/swiftui-simplex-architecture", exact: "0.7.0")
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
### Basic Usage
```Swift
@Reducer
struct MyReducer {
    enum ViewAction {
        case increment
        case decrement
    }
    func reduce(into state: StateContainer<MyView>, action: Action) -> SideEffect<Self> {
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

@ViewState
struct MyView: View {
    @State var counter = 0
    
    let store: Store<MyReducer> = Store(reducer: MyReducer())

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

### ReducerState

Use ReducerState if you want to keep the state only in the Reducer.
ReducerState is also effective to improve performance because the View is not updated even if the value is changed.

This is the example code
```Swift
@Reducer
struct MyReducer {
    enum ViewAction {
        case increment
        case decrement
    }

    struct ReducerState {
        var totalCalledCount = 0
    }

    func reduce(into state: StateContainer<MyView>, action: Action) -> SideEffect<Self> {
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

@ViewState
struct MyView: View {
    @State var counter = 0

    let store: Store<MyReducer>

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

### ReducerAction

If there are Actions that you do not want to expose to View, ReducerAction is effective.
This is the sample code:

```Swift
@Reducer
struct MyReducer {
    enum ViewAction {
        case login
    }

    enum ReducerAction {
        case loginResponse(TaskResult<Response>)
    }

    @Dependency(\.authClient) var authClient

    func reduce(into state: StateContainer<MyView>, action: Action) -> SideEffect<Self> {
        switch action {
        case .login:
            return .run { [email = state.email, password = state.password] send in
                await send(
                    .loginResponse(
                        TaskResult { try await authClient.login(email, password) }
                    )
                )
            }
        case let .loginResponse(result):
            ...
            return .none
        }
    }
}

@ViewState
struct MyView: View {
    @State var email: String = ""
    @State var password: String = ""

    let store: Store<MyReducer>

    init(authClient: AuthClient) {
        store = Store(reducer: MyReducer())
    }

    var body: some View {
        VStack {
            ...
            Button("Login") {
                send(.login)
            }
        }
    }
}
```

### Pullback Action

If you want to send the Action of the child Reducer to the parent Reducer, use pullback.
This is the sample code.

```Swift
@ViewState
struct ParentView: View {
    let store: Store<ParentReducer> = Store(reducer: ParentReducer())

    var body: some View {
        ChildView()
            .pullback(to: /ParentReducer.Action.child, parent: self)
    }
}

@Reducer
struct ParentReducer {
    enum ViewAction {
    }
    enum ReducerAction {
        case child(ChildReducer.Action)
    }

    func reduce(into state: StateContainer<ParentView>, action: Action) -> SideEffect<Self> {
        switch action {
        case .child(.onButtonTapped):
            // do something
            return .none
        }
    }
}

@ViewState
struct ChildView: View, ActionSendable {
    let store: Store<ChildReducer> = Store(reducer: ChildReducer())

    var body: some View {
        Button("Child View") {
            send(.onButtonTapped)
        }
    }
}

@Reducer
struct ChildReducer {
    enum ViewAction {
        case onButtonTapped
    }

    func reduce(into state: StateContainer<ChildView>, action: Action) -> SideEffect<Self> {
        switch action {
        case .onButtonTapped:
            return .none
        }
    }
}
```

### Testing
You can write a test like this.
```Swift
let testStore = TestView().testStore(viewState: .init())
await testStore.send(.increment) {
    $0.count = 1
}

let testStore = TestView().testStore(viewState: .init())
await testStore.send(.send)
await testStore.receive(.increment) {
    $0.count = 1
}
```
