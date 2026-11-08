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
    @Entry var tooltipBottomInset: CGFloat = 0
    @Entry var tooltipStaysOnScreen: Bool = false
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
    
    /// Zero by default. Keeps tooltips this far from the left and right screen edges, in both directions (for example clear of a side bar): top and bottom tooltips move inward, and a leading or trailing tooltip that would run into an inset opens on another side. Apply it after `tooltipContainer(_:)` or on an ancestor of it.
    @ViewBuilder func tooltipHorizontalInsets(left: CGFloat, right: CGFloat) -> some View {
        environment(\.tooltipLeftInset, left)
            .environment(\.tooltipRightInset, right)
    }
    
    /// Zero by default. Keeps tooltips this far from the bottom screen edge, or clear of the bottom safe area when that is larger (for example above a floating tab bar): a bottom tooltip that would run into it opens on top. Apply it after `tooltipContainer(_:)` or on an ancestor of it.
    @ViewBuilder func tooltipBottomInset(_ inset: CGFloat) -> some View {
        environment(\.tooltipBottomInset, inset)
    }
    
    /// Off by default. When on, a top or bottom tooltip that fits on no side moves up or down inside the screen (below the top safe area, above the bottom edge `tooltipBottomInset(_:)` keeps clear of), over its target if needed, instead of running past the screen edge. Apply it after `tooltipContainer(_:)` or on an ancestor of it.
    @ViewBuilder func tooltipStaysOnScreen(_ isEnabled: Bool) -> some View {
        environment(\.tooltipStaysOnScreen, isEnabled)
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
