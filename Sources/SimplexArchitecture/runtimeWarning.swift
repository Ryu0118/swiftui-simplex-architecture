import Foundation

// FIXME: Fix Runtime Error
func runtimeWarning(_ message: String, file: String = #file, line: Int = #line) {
    #if DEBUG
    DispatchQueue.global(qos: .userInteractive).async {
        // If you got here, please check console for more info
        print("Runtime warning: \(message): file \(file.fileName), line \(line)")
    }
    #endif
}

fileprivate extension String {
    var fileName: String { URL(fileURLWithPath: self).lastPathComponent }
}
