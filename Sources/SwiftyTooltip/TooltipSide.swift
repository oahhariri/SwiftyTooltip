//
//  TooltipSide.swift
//  Mahly
//
//  Created by Abdulrahman Ameen Hariri on 26/03/2025.
//

import SwiftUI

public enum TooltipSide: String {
    case top, bottom, trailing, leading
}

internal let tooltipCoordinateSpace = "tooltip-coordinate-space"

/// Coordinate-space name scoped to a single tooltip context.
///
/// Each `.tooltipContainer(_:)` declares its own coordinate space using this
/// name, and every target of that context measures its frame against the same
/// per-context name. Deriving the name from the context id keeps the spaces of
/// stacked containers distinct, so two `.tooltipContainer` modifiers on the same
/// view no longer collide on a single shared `tooltipCoordinateSpace` name
/// (which previously broke every context but the innermost one).
internal func tooltipCoordinateSpace(for context: String) -> String {
    "\(tooltipCoordinateSpace)_\(context)"
}
