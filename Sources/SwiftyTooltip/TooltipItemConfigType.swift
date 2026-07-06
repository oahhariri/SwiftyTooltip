//
//  TooltipItemConfigType.swift
//  Mahly
//
//  Created by Abdulrahman Ameen Hariri on 27/03/2025.
//

import SwiftUI

public protocol TooltipItemConfigType: Identifiable&Equatable {
    var id : String { get }
    var side: TooltipSide { get }
    var backgroundBehavuior: TooltipBackgroundBehavuior { get }
    var spacing: CGFloat { get }
    var backgroundColor: Color { get }
    var arrowWidth: CGFloat { get }
    var spotlightCutInteractive: Bool { get }
    var spotlightCutPadding: CGFloat { get }
    var spotlightCutCornerRadius: CornerRadius { get }
    /// How the tooltip animates in when it appears.
    var appearanceAnimation: TooltipAppearanceAnimation { get }
}

public extension TooltipItemConfigType {
    /// Defaults to the classic jump animation so existing conformers keep their
    /// current behaviour without any change.
    var appearanceAnimation: TooltipAppearanceAnimation { .jump }
}

public enum TooltipBackgroundBehavuior: String {
    case dismiss
    case block
    case simultaneousTabs
}

/// The animation played when a tooltip first appears.
public enum TooltipAppearanceAnimation: String, Equatable {
    /// The original bobbing "jump" animation, played at the tooltip's resting
    /// position.
    case jump

    /// The tooltip emerges from the target view: it starts small at the target's
    /// center and springs out to its resting position and full size, with the
    /// scale anchored toward the target edge (iOS-26 liquid-glass menu style).
    case emergeFromTarget

    /// Whether this style includes the emerge-from-target motion.
    var includesEmerge: Bool {
        self == .emergeFromTarget
    }

    /// Whether this style includes the jump motion.
    var includesJump: Bool {
        self == .jump
    }
}
