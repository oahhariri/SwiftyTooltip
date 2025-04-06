//
//  ToolTip+ViewModifiers.swift
//
//
//  Created by Abdulrahman Ameen Hariri on 26/03/2025.
//

import SwiftUI
import SwiftUIOverlayContainer

struct TooltipEnvironmentModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlayContainer(OverlayContainers.tooltipOverlayContiners, containerConfiguration: OverlayContainerConfig())
            .coordinateSpace(name: tooltipCoordinateSpace)
    }
}

// MARK: - View Extensions

public extension View {
    
    @ViewBuilder func tooltipContainer() -> some View {
        modifier(TooltipEnvironmentModifier())
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
