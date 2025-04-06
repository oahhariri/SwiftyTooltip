//
//  ViewSizeAdapter.swift
//  SwiftyTooltip
//
//  Created by Abdulrahman Ameen Hariri on 06/04/2025.
//

import SwiftUI

struct ViewSizeAdapter: ViewModifier {
    
    var viewSize: ((_ continerSize:CGSize) ->())
    
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            view(content: content)
        } else {
            lagacyView(content: content)
        }
        
    }
    
    @available(iOS 16.0, *)
    @ViewBuilder private func view(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self) { geometry in
                geometry.size
            } action: { geo in
                DispatchQueue.main.async {
                    viewSize(geo)
                }
            }
    }
    
    
    @ViewBuilder private func lagacyView(content: Content) -> some View {
        content
            .background(GeometryReader { geo in
                Color.clear
                    .onChange(of: geo.size, perform: { newValue in
                        DispatchQueue.main.async {
                            viewSize(newValue)
                        }
                    })
                    .onAppear {
                        DispatchQueue.main.async {
                            viewSize(geo.size)
                        }
                    }
            })
    }
}

extension View {
    
    
    @ViewBuilder func getViewSize(_ viewSize: @escaping (@MainActor(_ continerSize:CGSize) ->())) -> some View {
        modifier(ViewSizeAdapter(viewSize: viewSize))
    }
}
