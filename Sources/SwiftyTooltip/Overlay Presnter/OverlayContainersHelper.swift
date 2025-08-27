//
//  OverlayContainersHelper.swift
//  SwiftyTooltip
//
//  Created by Abdulrahman Ameen Hariri on 06/04/2025.
//

import SwiftUIOverlayContainer
import SwiftUI

class OverlayContainersHelper {
    
    static func show<Content:View>(contextId: String,id: UUID? = nil, _ content: @escaping () -> Content) {
        DispatchQueue.main.async {
            let manager = ContainerManager.share
            
            manager.show(view:content(),
                         with:id,
                         in: "\(OverlayContainers.tooltipOverlayContiners)_\(contextId)",
                         using: OverlayContainerConfig(),
                         animated: false)
        }
    }
    
    static func dismiss(contextId: String,id: UUID? = nil, animated: Bool = false) {
        DispatchQueue.main.async {
            if let id = id {
                ContainerManager.share.dismiss(view: id,
                                               in: "\(OverlayContainers.tooltipOverlayContiners)_\(contextId)",
                                               animated: animated)
            } else {
                ContainerManager.share.dismissAllView(in: ["\(OverlayContainers.tooltipOverlayContiners)_\(contextId)"],
                                                      animated: animated)
            }
        }
    }
}
