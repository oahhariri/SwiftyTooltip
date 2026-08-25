//
//  TooltipShadow.swift
//  SwiftyTooltip
//
//  Created by Abdulrahman Ameen Hariri on 25/08/2025.
//

import SwiftUI

/// The shadow drawn behind the tooltip bubble.
///
/// Configure it per item through `TooltipItemConfigType.shadow`; conformers that
/// don't override it keep the SDK's original shadow (`.default`).
public struct TooltipShadow: Equatable {

    public var color: Color
    public var radius: CGFloat
    public var x: CGFloat
    public var y: CGFloat

    public init(color: Color = Color.black.opacity(0.4),
                radius: CGFloat = 9,
                x: CGFloat = 0,
                y: CGFloat = 3) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }

    /// The shadow the SDK has always drawn behind tooltips.
    public static let `default` = TooltipShadow()

    /// No shadow at all.
    public static let none = TooltipShadow(color: .clear, radius: 0, x: 0, y: 0)

    /// Whether this shadow would actually paint anything — a clear color, or a
    /// zero radius with no offset, draws nothing, so the modifier is skipped.
    internal var isVisible: Bool {
        color != .clear && (radius > 0 || x != 0 || y != 0)
    }
}

internal extension View {
    /// Applies `shadow`, or nothing at all when it isn't visible.
    @ViewBuilder func tooltipShadow(_ shadow: TooltipShadow) -> some View {
        if shadow.isVisible {
            self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
        } else {
            self
        }
    }
}
