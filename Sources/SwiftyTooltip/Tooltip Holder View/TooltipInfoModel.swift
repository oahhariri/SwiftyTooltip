//
//  TooltipInfoModel.swift
//  Mahly
//
//  Created by Abdulrahman Ameen Hariri on 06/04/2025.
//
import SwiftUI

struct TooltipInfoModel<Item: TooltipItemConfigType>: Equatable & Identifiable {
    var id: String {
        item.id
    }

    var item: Item
    var targetFrame: CGRect

    /// A copy with `targetFrame` translated by `-origin`, i.e. converted from the
    /// coordinate space whose origin (in the overlay's local space) is `origin`,
    /// into that local space. `origin == .zero` returns an identical frame.
    func convertingTargetFrame(by origin: CGPoint) -> TooltipInfoModel {
        guard origin != .zero else { return self }
        var copy = self
        copy.targetFrame = targetFrame.offsetBy(dx: -origin.x, dy: -origin.y)
        return copy
    }
}
