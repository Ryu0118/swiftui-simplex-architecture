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

## Examples
We've provided example implementations within this library. Currently, we only feature a simple GitHub repository search app, but we plan to expand with more examples in the future.
- [Github Repository Search App](https://github.com/Ryu0118/swiftui-simplex-architecture/tree/main/Examples/Github-App)

## Installation
```Swift
let package = Package(
    name: "YourProject",
    ...
    dependencies: [
        .package(url: "https://github.com/Ryu0118/swiftui-simplex-architecture", exact: "0.8.0")
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

## Basic Usage
The usage is almost the same as in TCA.
State definitions use property wrappers used in SwiftUI, such as `@State`, `@Binding`, `@FocusState.`
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
Actions used in the View are defined using an enum called `ViewAction`. For actions that you'd like to keep private and are used exclusively within the `Reducer`, utilize the `ReducerAction`.

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
    ...
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
    ...
    init() {
        store = Store(reducer: MyReducer(), initialReducerState: MyReducer.ReducerState())
    }
    ...
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
```

## Macro
There are two macros in this library:
- `@Reducer`
- `@ViewState`

### `@Reducer`
`@Reducer` is a macro that integrates `ViewAction` and `ReducerAction` to generate `Action`.
```Swift
@Reducer
struct MyReducer {
    enum ViewAction {
        case loginButtonTapped
    }
    enum ReducerAction {
        case loginResponse(TaskResult<User>)
    }
    // expand to ↓
    enum Action {
        case loginButtonTapped
        case loginResponse(TaskResult<User>)
        
        init(viewAction: ViewAction) {
            switch viewAction {
            case .loginButtonTapped:
                self = .loginButtonTapped
            }
        }
        
        init(reducerAction: ReducerAction) {
            switch reducerAction {
            case .loginResponse(let arg1):
                self = .loginResponse(arg1)
            }
        }
    }
    ...
}
```
`Reducer.reduce(into:action:)` no longer needs to be prepared for two actions, `ViewAction` and `ReducerAction`, but can be integrated into `Action`.

### `@ViewState`
`@ViewState` creates a `ViewState` structure and conforms it to the `ActionSendable` protocol.
```Swift
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
    // expand to ↓
    struct ViewState: ViewStateProtocol {
        var counter = 0
        static let keyPathMap: [PartialKeyPath<ViewState>: PartialKeyPath<MyView>] = [\.counter: \.counter]
    }
}
```
The ViewState structure serves two main purposes:

- To make properties such as store and body of View inaccessible to Reducer.
- To make it testable.

Also, By conforming to the ActionSendable protocol, you can send Actions to the Store.

## Testing
For testing, we use TestStore. This requires an instance of the ViewState struct, which is generated by the @ViewState macro. Additionally, we'll conduct further operations to assert how its behavior evolves when an action is dispatched.
```Swift
@MainActor
func testReducer() async {
    let store = MyView().testStore(viewState: .init())
}
```
Each step of the way we need to prove that state changed how we expect. For example, we can simulate the user flow of tapping on the increment and decrement buttons:
```Swift
@MainActor
func testReducer() async {
    let store = MyView().testStore(viewState: .init())
    await store.send(.increment) {
        $0.count = 1
    }
    await store.send(.decrement) {
        $0.count = 0
    }
}
```
Furthermore, when effects are executed by steps and data is fed back into the store, it's necessary to assert on those effects.
```Swift
@MainActor
func testReducer() async {
    let store = MyView().testStore(viewState: .init())
    await store.send(.fetchData)
    await store.send(.fetchDataResponse) {
        $0.data = ...
    }
}
```
If you're using [swift-dependencies](https://github.com/pointfreeco/swift-dependencies), you can perform dependency injection as follows:
```Swift
let store = MyView().testStore(viewState: .init()) {
    $0.apiClient.fetchData = { _ in ... }
}
```
