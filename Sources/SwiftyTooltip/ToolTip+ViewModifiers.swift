//
//  ToolTip+ViewModifiers.swift
//
//
//  Created by Abdulrahman Ameen Hariri on 26/03/2025.
//

import SwiftUI
import SwiftUIOverlayContainer

struct TooltipEnvironmentModifier: ViewModifier {
    var context: String?
    
    var containerName: String {
        guard let context else { return OverlayContainers.tooltipOverlayContiners }
        
        return "\(OverlayContainers.tooltipOverlayContiners)_\(context)"
    }
    
    func body(content: Content) -> some View {
        content
            .overlayContainer(containerName,
                              containerConfiguration: OverlayContainerConfig())
            .coordinateSpace(name: tooltipCoordinateSpace)
    }
}

extension EnvironmentValues {
    @Entry var tooltipCentersOnTargetInRTL: Bool = false
    @Entry var tooltipLeftInset: CGFloat = 0
    @Entry var tooltipRightInset: CGFloat = 0
}

// MARK: - View Extensions

public extension View {
    
//    @ViewBuilder func tooltipContainer() -> some View {
//        modifier(TooltipEnvironmentModifier())
//    }
    
    @ViewBuilder func tooltipContainer<ContextType: TooltipContextType>(_ context: ContextType) -> some View {
        modifier(TooltipEnvironmentModifier(context: context.id))
    }
    
    /// Off by default. Apply it after `tooltipContainer(_:)` or on an ancestor of it.
    @ViewBuilder func tooltipCentersOnTargetInRTL(_ isEnabled: Bool) -> some View {
        environment(\.tooltipCentersOnTargetInRTL, isEnabled)
    }
    
    /// Zero by default. Keeps top and bottom tooltips this far from the left and right screen edges, in both directions (for example clear of a side bar). Apply it after `tooltipContainer(_:)` or on an ancestor of it.
    @ViewBuilder func tooltipHorizontalInsets(left: CGFloat, right: CGFloat) -> some View {
        environment(\.tooltipLeftInset, left)
            .environment(\.tooltipRightInset, right)
    }
    
    @ViewBuilder func tooltipTarget<Context: TooltipContextType>(context: Context, _ id: String) -> some View {
        TooltipTargetView(context: context, id: id){
            self
        }
    }
    
    @ViewBuilder func tooltip<Context: TooltipContextType, Item: TooltipItemConfigType, Content: View>(
        context: Context,
        item: Binding<Item?>,
        backgroundColor: Color = Color.gray.opacity(0.50),
        @ViewBuilder content: @escaping (Item) -> Content) -> some View {
            TooltipItemView(context: context, item: item, backgroundColor: backgroundColor, tooltipContent: content) {
                self
            }
        }
}
