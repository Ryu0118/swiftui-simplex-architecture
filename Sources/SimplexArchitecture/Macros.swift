@attached(member, names: named(States), named(getStore), named(Reducer), named(_store))
@attached(conformance)
public macro StoreBuilder<Reducer: ReducerProtocol>(reducer: Reducer) = #externalMacro(module: "SimplexArchitectureMacrosPlugin", type: "StoreBuilder")

@attached(member, names: named(States), named(Reducer))
@attached(conformance)
public macro ManualStoreBuilder<Reducer: ReducerProtocol>(reducer: Reducer.Type) = #externalMacro(module: "SimplexArchitectureMacrosPlugin", type: "ManualStoreBuilder")

@attached(member, names: named(State), named(Target))
@attached(conformance)
public macro Reducer(_ target: String) = #externalMacro(module: "SimplexArchitectureMacrosPlugin", type: "ReducerBuilderMacro")
