import SwiftUI

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public extension View {
    func confirmationDialog<Target: ActionSendable>(
        target: Target,
        unwrapping value: Binding<ConfirmationDialogState<Target.Reducer.Action>?>
    ) -> some View {
        self.confirmationDialog(
            value.wrappedValue.flatMap { Text($0.title) } ?? Text(""),
            isPresented: value.isPresent(),
            titleVisibility: value.wrappedValue.map { .init($0.titleVisibility) } ?? .automatic,
            presenting: value.wrappedValue,
            actions: { confirmationDialogState in
                ForEach(confirmationDialogState.buttons) { button in
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

    func confirmationDialog<Target: ActionSendable>(
        target: Target,
        unwrapping value: Binding<ConfirmationDialogState<Target.Reducer.ReducerAction>?>
    ) -> some View {
        self.confirmationDialog(
            value.wrappedValue.flatMap { Text($0.title) } ?? Text(""),
            isPresented: value.isPresent(),
            titleVisibility: value.wrappedValue.map { .init($0.titleVisibility) } ?? .automatic,
            presenting: value.wrappedValue,
            actions: { confirmationDialogState in
                ForEach(confirmationDialogState.buttons) { button in
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
