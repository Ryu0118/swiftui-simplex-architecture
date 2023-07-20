import Foundation
import os

// https://www.pointfree.co/blog/posts/70-unobtrusive-runtime-warnings-for-libraries
func runtimeWarning(_ message: String, file: String = #file, line: Int = #line) {
    #if DEBUG
    var info = Dl_info()
    dladdr(
        dlsym(
            dlopen(nil, RTLD_LAZY),
            "$s10Foundation15AttributeScopesO7SwiftUIE05swiftE0AcDE0D12UIAttributesVmvg"
        ),
        &info
    )
    os_log(
        .fault,
        dso: info.dli_fbase,
        log: OSLog(
            subsystem: "com.apple.runtime-issues",
            category: "SimplexArchitecture"
        ),
        "%@",
        """
        file: \(file), line: \(line)
        \(message)
        """
    )
    #endif
}
