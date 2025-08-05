import Foundation
@testable import Recap

// MARK: - Test Mock Implementation

struct MockWindow: WindowTitleProviding {
    let title: String?
    
    init(title: String?) {
        self.title = title
    }
}