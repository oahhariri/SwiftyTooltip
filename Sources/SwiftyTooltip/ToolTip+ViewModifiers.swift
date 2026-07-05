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
    
    /// Name of the coordinate space this container declares. Scoped to the
    /// context so stacking multiple containers doesn't collide on one shared
    /// space name; falls back to the global name when no context is given.
    private var coordinateSpaceName: String {
        guard let context else { return tooltipCoordinateSpace }
        return tooltipCoordinateSpace(for: context)
    }

    func body(content: Content) -> some View {
        content
            .overlayContainer(containerName,
                              containerConfiguration: OverlayContainerConfig())
            .coordinateSpace(name: coordinateSpaceName)
    }
}

// MARK: - View Extensions

public extension View {
    
//    @ViewBuilder func tooltipContainer() -> some View {
//        modifier(TooltipEnvironmentModifier())
//    }
    
    @ViewBuilder func tooltipContainer<ContextType: TooltipContextType>(_ context: ContextType) -> some View {
        modifier(TooltipEnvironmentModifier(context: context.id))
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
