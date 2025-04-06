//
//  SpotlightBackgroundView.swift
//  Mahly
//
//  Created by Abdulrahman Ameen Hariri on 27/03/2025.
//

import SwiftUI
import Foundation

public enum CornerRadius {
    case circle
    case rounded(CGFloat)
}

internal struct SpotlightBackgroundView: View {
    
    let backgroundColor: Color
    let cutFarmeRect: CGRect
    var cornerRadius:CornerRadius = .circle
    
    var body: some View {
        ZStack {
            RoundedHoleShape(holeRect: cutFarmeRect,
                             cornerRadius: getCornerRadius())
            .fill(backgroundColor, style: FillStyle(eoFill: true))
        }
    }
    
    private func getCornerRadius() -> CGFloat {
        switch cornerRadius {
        case .circle:
            return cutFarmeRect.width / 2
        case .rounded(let radius):
            return radius
        }
    }
}

private struct RoundedHoleShape: Shape {
    let holeRect: CGRect
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        let roundedHole = Path(roundedRect: holeRect,
                               cornerRadius: cornerRadius)
        path.addPath(roundedHole)
        return path
    }
}
