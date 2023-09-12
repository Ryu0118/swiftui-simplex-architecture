//MIT License
//
//Copyright (c) 2020 Point-Free, Inc.
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

// https://www.pointfree.co/blog/posts/70-unobtrusive-runtime-warnings-for-libraries

import Foundation
import os

func runtimeWarning(_ message: String) {
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
        dso: dso,
        log: OSLog(
            subsystem: "com.apple.runtime-issues",
            category: "SimplexArchitecture"
        ),
        "%@",
        message
    )
    #endif
}

@usableFromInline
let dso = { () -> UnsafeMutableRawPointer in
    let count = _dyld_image_count()
    for i in 0..<count {
        if let name = _dyld_get_image_name(i) {
            let swiftString = String(cString: name)
            if swiftString.hasSuffix("/SwiftUI") {
                if let header = _dyld_get_image_header(i) {
                    return UnsafeMutableRawPointer(mutating: UnsafeRawPointer(header))
                }
            }
        }
    }
    return UnsafeMutableRawPointer(mutating: #dsohandle)
}()