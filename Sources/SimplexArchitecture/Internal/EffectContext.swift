import Foundation

/// Enum to determine parent's Effect
enum EffectContext {
    @TaskLocal static var id: UUID?
}
