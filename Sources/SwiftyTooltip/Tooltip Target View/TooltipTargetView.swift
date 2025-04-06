//
//  TooltipTargetView.swift
//  Mahly
//
//  Created by Abdulrahman Ameen Hariri on 26/03/2025.
//

import SwiftUI

struct TooltipTargetView<Content: View, Context: TooltipContextType>: View {
    
    let context: Context
    let id: String
    @Environment(\.tooltipAction) var tooltipAction
    
    @ViewBuilder var content: () -> Content
    
    public var body: some View {
        content()
            .getViewFrame(coordinateSpace: .named(tooltipCoordinateSpace)) { frame in
                tooltipAction?(.register(context.id, id: id, frame: frame))
            }
            .onDisappear {
                tooltipAction?(.unregister(context.id, id: id))
            }
            .uiKitViewControllerLifeCycle { lifecycle in
                guard lifecycle == .onDeinit else { return }
                tooltipAction?(.unregister(context.id, id: id))
            }
    }
}
