//

import Foundation
import SwiftUI

@Observable
class NavigationModel {
    static let shared = NavigationModel()
    
    public enum navigationView {
        case splash, onboarding, home
    }
    
    @MainActor
    public private(set) var currentNav = navigationView.splash
    @MainActor
    public private(set) var entityBindingContext: entityBindingContext? = nil
        
    @MainActor
    public func navigate(_ to: navigationView) {
        self.currentNav = to
    }
    
    @MainActor
    public func triggerEntityBinding(_ context: entityBindingContext) {
        self.entityBindingContext = context
    }
    
    @MainActor
    public func closeEntityBinding() {
        self.entityBindingContext = nil
    }
    
    @MainActor
    func reset() {
        self.currentNav = .onboarding
        self.entityBindingContext = nil
    }
}

struct entityBindingContext: Equatable {
    let entity: wordEntity
    let storyId: Int64?
    let questionId: Int64?
}
