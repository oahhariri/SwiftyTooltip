//
//  TooltipItemViewModel.swift
//  
//
//  Created by Abdulrahman Ameen Hariri on 26/03/2025.
//

import SwiftUI

@globalActor actor TooltipsBackgroundActor: GlobalActor {
    static var shared = TooltipsBackgroundActor()
}

class TooltipItemViewModel<Context: TooltipContextType,Item: TooltipItemConfigType>: ObservableObject {
    let context: Context
    private(set) var targets: [String: CGRect] = [:]
    @Published var tooltipInfo: TooltipInfoModel<Item>?
    
    init(context: Context) {
        self.context = context
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
    @MainActor
    func assign(_ context: String, item: Item, frame: CGRect) {
        guard context == self.context.id else {return}
        let targetFrame = frame.insetBy(dx: -(item.spotlightCutPadding),
                                        dy: -(item.spotlightCutPadding))
        self.tooltipInfo = .init(item: item, targetFrame: targetFrame)
    }
}


