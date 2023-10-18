import SwiftUI

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public extension View {
    func alert<Target: ActionSendable>(
        target: Target,
        unwrapping value: Binding<AlertState<Target.Reducer.ViewAction>?>
    ) -> some View {
        alert(
            (value.wrappedValue?.title).map(Text.init) ?? Text(""),
            isPresented: value.isPresent(),
            presenting: value.wrappedValue,
            actions: { alertState in
                ForEach(alertState.buttons) { button in
                    Button(role: button.role.map(ButtonRole.init)) {
                        switch button.action.type {
                        case let .send(action):
                            if let action = action {
                                target.send(action)
                            }
                        case let .animatedSend(action, animation):
                            if let action = action {
                                target.send(action, animation: animation)
                            }
                        }
                    } label: {
                        Text(button.label)
                    }
                }
            },
            message: { $0.message.map { Text($0) } }
        )
    }

    func alert<Target: ActionSendable>(
        target: Target,
        unwrapping value: Binding<AlertState<Target.Reducer.ReducerAction>?>
    ) -> some View {
        alert(
            (value.wrappedValue?.title).map(Text.init) ?? Text(""),
            isPresented: value.isPresent(),
            presenting: value.wrappedValue,
            actions: { alertState in
                ForEach(alertState.buttons) { button in
                    Button(role: button.role.map(ButtonRole.init)) {
                        switch button.action.type {
                        case let .send(action):
                            if let action = action {
                                _ = target.store.send(action, target: target)
                            }
                        case let .animatedSend(action, animation):
                            if let action = action {
                                _ = withAnimation(animation) {
                                    target.store.send(action, target: target)
                                }
                            }
                        }
                    } label: {
                        Text(button.label)
                    }
                }
            },
            message: { $0.message.map { Text($0) } }
        )
    }
}
