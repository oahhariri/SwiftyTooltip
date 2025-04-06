//
//  OverlayContainers.swift
//  SwiftyTooltip
//
//  Created by Abdulrahman Ameen Hariri on 06/04/2025.
//

import SwiftUIOverlayContainer
import SwiftUI

struct OverlayContainers {
    static let tooltipOverlayContiners  = "tooltipOverlayContiners"

}
 
 
struct OverlayContainerConfig: ContainerConfigurationProtocol {
    
    var displayType: ContainerViewDisplayType = .vertical
    var queueType: ContainerViewQueueType =  .oneByOne
    var autoDismiss: ContainerViewAutoDismiss? = .disable
    var alignment: Alignment? = .top
    var dismissGesture: ContainerViewDismissGesture? = .disable
    var transition: AnyTransition? = .none
    
}
