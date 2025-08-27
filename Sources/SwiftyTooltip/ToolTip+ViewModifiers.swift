//
//  ToolTip+ViewModifiers.swift
//
//
//  Created by Abdulrahman Ameen Hariri on 26/03/2025.
//

import SwiftUI
import SwiftUIOverlayContainer

struct TooltipEnvironmentModifier: ViewModifier {
     var contexts: [String] = []
    func body(content: Content) -> some View {
        
     //   ZStack {
            
            content
                .overlay(TooltipEnvironmentHelper(contexts: contexts))
                .coordinateSpace(name: tooltipCoordinateSpace)
            
            
      //  }
     
    }
}
//extension View {
//    @ViewBuilder func apply(_ contexts: [String]) -> some View {
//        TooltipEnvironmentHelper(contexts) {
//            self
//        }
//    }
//}

struct TooltipEnvironmentHelper: View {
    var contexts: [String] = []
    
    public var body: some View {
        ForEach(contexts, id: \.self) { context in
            overlayContainer("\(OverlayContainers.tooltipOverlayContiners)_\(context)",
                             containerConfiguration: OverlayContainerConfig())
        }
    }
}
// MARK: - View Extensions

public extension View {
    
    @ViewBuilder func tooltipContainer<ContextType: TooltipContextType>(_ contexts: [ContextType]) -> some View {
        modifier(TooltipEnvironmentModifier(contexts: contexts.map{$0.id}))
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
