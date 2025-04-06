//
//  ViewFrameAdapter.swift
//  SwiftyTooltip
//
//  Created by Abdulrahman Ameen Hariri on 06/04/2025.
//

import SwiftUI

struct ViewFrameAdapter: ViewModifier {
    
    var viewFrame: ((_ frame: CGRect) -> Void)
    let coordinateSpace: CoordinateSpace
    
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
            .onGeometryChange(for: CGRect.self) { geo in
                geo.frame(in: coordinateSpace)
            } action: { geo in
                DispatchQueue.main.async {
                    viewFrame(geo)
                }
            }
    }
    
    @ViewBuilder private func lagacyView(content: Content) -> some View {
        content
            .background(GeometryReader { geo in
                Color.clear
                    .onChange(of: geo.frame(in: coordinateSpace), perform: { newValue in
                        DispatchQueue.main.async {
                            viewFrame(newValue)
                        }
                    })
                    .onAppear {
                        DispatchQueue.main.async {
                            viewFrame(geo.frame(in: coordinateSpace))
                        }
                    }
            })
    }
}

extension View {
    func getViewFrame(coordinateSpace: CoordinateSpace, _ viewFrame: @escaping ((_ frame: CGRect) -> Void)) -> some View {
        modifier(ViewFrameAdapter(viewFrame: viewFrame,coordinateSpace: coordinateSpace))
    }
}
