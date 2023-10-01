import Foundation

typealias Original = @convention(thin) (UnownedJob) -> Void
typealias Hook = @convention(thin) (UnownedJob, Original) -> Void

private let _swift_task_enqueueGlobal_hook = dlsym(
    dlopen(nil, 0), "swift_task_enqueueGlobal_hook"
).assumingMemoryBound(to: Hook?.self)

var swift_task_enqueueGlobal_hook: Hook? {
    get { _swift_task_enqueueGlobal_hook.pointee }
    set { _swift_task_enqueueGlobal_hook.pointee = newValue }
}
