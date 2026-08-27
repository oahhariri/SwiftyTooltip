//
//  TooltipItemViewModel.swift
//  
//
//  Created by Abdulrahman Ameen Hariri on 26/03/2025.
//

import SwiftUI
import OrderedCollections

@globalActor actor TooltipsBackgroundActor: GlobalActor {
    static var shared = TooltipsBackgroundActor()
}


class TooltipItemViewModel<Context: TooltipContextType,Item: TooltipItemConfigType>: ObservableObject {
    let context: Context
    private var targets: OrderedDictionary<String, CGRect> = [:]
    @Published var tooltipInfo: TooltipInfoModel<Item>?
    
    init(context: Context) {
        self.context = context
    }
    
    @TooltipsBackgroundActor
    func getTarget(_ id: String) -> CGRect? {
        self.targets[id]
    }
    
    @TooltipsBackgroundActor
    func getTargets() -> OrderedDictionary<String, CGRect> {
        self.targets
    }
    
    @TooltipsBackgroundActor
    func registerTarget(_ context: String,_ id: String, frame: CGRect) {
        guard context == self.context.id else {return}
        self.targets[id] = frame
    }
    
    @TooltipsBackgroundActor
    func unregisterTarget(_ context: String,_ id: String) {
        guard context == self.context.id else {return}
        targets.removeValue(forKey: id)
    }
    
    @TooltipsBackgroundActor
    func assign(_ context: String, item: Item, frame: CGRect) async {
        guard context == self.context.id else {return}
        let targetFrame = frame.insetBy(dx: -(item.spotlightCutPadding),
                                        dy: -(item.spotlightCutPadding))
        
        await setTooltipInfo(.init(item: item, targetFrame: targetFrame))
    }
    
    /// Publishes the tooltip, skipping an assignment that changes nothing.
    ///
    /// Every registered target in this context drives an `assign`, so an open
    /// tooltip is re-assigned an identical model whenever *any* other target
    /// registers. Republishing it re-renders the presenter for no visible
    /// change; every observer downstream (`overlayCover`, the holder view's
    /// `onChange`) is equality-gated anyway, so skipping it is invisible.
    @MainActor
    private func setTooltipInfo(_ tooltipInfoModel: TooltipInfoModel<Item>) async {
        guard self.tooltipInfo != tooltipInfoModel else { return }
        self.tooltipInfo = tooltipInfoModel
    }
}


