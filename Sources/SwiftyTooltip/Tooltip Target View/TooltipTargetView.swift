//
//  TooltipTargetView.swift
//  Mahly
//
//  Created by Abdulrahman Ameen Hariri on 26/03/2025.
//

import SwiftUI

@globalActor actor TooltipTargetBackgroundActor: GlobalActor {
    static var shared = TooltipTargetBackgroundActor()
}

struct TooltipTargetView<Content: View, Context: TooltipContextType>: View {
    
    let context: Context
    let id: String
    @Environment(\.tooltipAction) var tooltipAction
    @Environment(\.currentTooltipContext) var currentTooltipContext
    
    @ViewBuilder var content: () -> Content
    
    public var body: some View {
        if let currentTooltipContext, currentTooltipContext == context.id {
            mainView()
        } else {
            content()
        }
    }
    
    func mainView() -> some View {
        content()
            .getViewFrame(coordinateSpace: .named(tooltipCoordinateSpace)) { frame in
                Task {@TooltipTargetBackgroundActor in
                    await tooltipAction?(.register(context.id, id: id, frame: frame))
                }
            }
            .onDisappear {
                Task {@TooltipTargetBackgroundActor in
                    await tooltipAction?(.unregister(context.id, id: id))
                }
            }
            .uiKitViewControllerLifeCycle { lifecycle in
                guard lifecycle == .onDeinit else { return }
                Task {@TooltipTargetBackgroundActor in
                    await tooltipAction?(.unregister(context.id, id: id))
                }
            }
    }
}
