//
//  EnvironmentKey.swift
//  SwiftyTooltip
//
//  Created by Abdulrahman Ameen Hariri on 06/04/2025.
//

import SwiftUI

private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        SafeAreaInsetsKey.safeAreaInsets()
    }
    
    static func safeAreaInsets() -> EdgeInsets {
        
        guard let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .init(.zero)
        }
        
        guard let window = firstScene.windows.first else {
            return .init(.zero)
        }
        
        let safeAreaInsets = window.safeAreaInsets
        
        return EdgeInsets(top: safeAreaInsets.top, leading: safeAreaInsets.right, bottom: safeAreaInsets.bottom, trailing: safeAreaInsets.left)
    }
}

extension EnvironmentValues {
    @MainActor
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}
