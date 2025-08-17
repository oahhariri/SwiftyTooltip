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
}

public enum TooltipBackgroundBehavuior: String {
    case dismiss
    case block
    case simultaneousTabs
}
