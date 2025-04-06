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
    var spacing: CGFloat { get }
    var backgroundColor: Color { get }
    var arrowWidth: CGFloat { get }
    var spotlightCutInteractive: Bool { get }
    var spotlightCutPadding: CGFloat { get }
    var spotlightCutCornerRadius: CornerRadius { get }
}
