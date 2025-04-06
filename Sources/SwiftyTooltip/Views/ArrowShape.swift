//
//  ArrowShape.swift
//  Mahly
//
//  Created by Abdulrahman Ameen Hariri on 27/03/2025.
//

import SwiftUI

struct ArrowShape: Shape {
    var cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)

        path.move(to: CGPoint(x: rect.midX - cornerRadius, y: rect.minY + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.midX + cornerRadius, y: rect.minY + cornerRadius), control: CGPoint(x: rect.midX, y: rect.minY))
 
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.closeSubpath()

        return path
    }
}
