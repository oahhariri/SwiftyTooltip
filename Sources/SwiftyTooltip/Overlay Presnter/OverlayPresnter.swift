//
//  OverlayPresnter.swift
//  SwiftyTooltip
//
//  Created by Abdulrahman Ameen Hariri on 06/04/2025.
//

import SwiftUIOverlayContainer
import SwiftUI

struct OverlayPresnter<FullscreenView: View,ViewType:Equatable&Identifiable>: ViewModifier {
    
    @State var viewID: UUID = UUID()
    @Binding var item: ViewType?
    @ViewBuilder var fullscreenView:(ViewType) -> FullscreenView
    
    func body(content: Content) -> some View {
        
        content
            .onChange(of: item) { newValue in
                guard let view = newValue else {
                    dimiss()
                    return
                }
                
                dimiss()
                
                OverlayContainersHelper.show(id: viewID) {
                    viewHolder(view: view)
                }
                
              
            }
    }
    
    
    @ViewBuilder func viewHolder(view: ViewType) -> some View {
        fullscreenView(view)
            .onDisappear {
                item = nil
                dimiss()
            }
    }
    
    private func dimiss() {
        OverlayContainersHelper.dismiss(id: viewID, animated: false)
        OverlayContainersHelper.dismiss(animated: false)
    }
}

extension View {
    func overlayCover<Content: View, Item:Equatable&Identifiable>(_ item:Binding<Item?>,
                                                                  content: @escaping (Item) -> Content)-> some View {
        
        modifier(OverlayPresnter(item: item,
                                fullscreenView: content))
    }
}
