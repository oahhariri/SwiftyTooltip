//
//  TooltipHolderView.swift
//  Mahly
//
//  Created by Abdulrahman Ameen Hariri on 26/03/2025.
//

import SwiftUI

struct TooltipHolderView<Item: TooltipItemConfigType, TooltipContent: View>: View {
    
    var tooltipInfo: TooltipInfoModel<Item>?
    
    let content: (Item) -> TooltipContent
    
    @Environment(\.layoutDirection) var layoutDirection
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @State private var tooltipSize: CGSize = .zero
    
    // Animation
    @State private var isAnimating: Bool = false
    @State private var jumpOffset: CGFloat = 0
    
    var backgroundColor: Color = Color.gray.opacity(0.50)
    var dismissToolTip:(()->())?
    
    init(tooltipInfo: TooltipInfoModel<Item>?, backgroundColor: Color,
         dismissToolTip:(()->())?=nil,
         content: @escaping (Item) -> TooltipContent) {
        self.tooltipInfo = tooltipInfo
        self.content = content
        self.backgroundColor = backgroundColor
        self.dismissToolTip = dismissToolTip
    }
    
    var body: some View {
        GeometryReader { geo in
            if let tooltipInfo = tooltipInfo {
                mainView(tooltipInfo, geo: geo)
            }
        }
        .ignoresSafeArea(.all)
        .edgesIgnoringSafeArea(.all)
        .onChange(of: tooltipInfo) { _ in
            startAnimation()
        }
        .onFirstAppear {
            startAnimation()
        }
        .disabledView(isAnimating)
    }
}

//MARK: - Views
extension TooltipHolderView {
    
    @ViewBuilder func mainView(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            
            backgroundView(tooltipInfo)
            
            tooltipView(tooltipInfo, geo: geo)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    @ViewBuilder func backgroundView(_ tooltipInfo: TooltipInfoModel<Item>) -> some View {
        SpotlightBackgroundView(
            backgroundColor: backgroundColor,
            cutFarmeRect: tooltipInfo.targetFrame,
            cornerRadius: tooltipInfo.item.spotlightCutCornerRadius
        )
        .ignoresSafeArea(.all)
        .edgesIgnoringSafeArea(.all)
        .contentShape(enabled: !tooltipInfo.item.spotlightCutInteractive)
        .onTapGesture {
            guard tooltipInfo.item.backgroundBehavuior != .simultaneousTabs else {return}
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            
            switch tooltipInfo.item.backgroundBehavuior {
            case .block:
                startAnimation()
            case .dismiss, .simultaneousTabs:
                DispatchQueue.main.async {
                    dismissToolTip?()
                }
            }
            
        }
        .simultaneousGesture(DragGesture(minimumDistance: 15, coordinateSpace: .local).onEnded({ _ in
            guard tooltipInfo.item.backgroundBehavuior != .simultaneousTabs else {return}
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            
            switch tooltipInfo.item.backgroundBehavuior {
            case .block:
                startAnimation()
            case .dismiss, .simultaneousTabs:
                DispatchQueue.main.async {
                    dismissToolTip?()
                }
            }
        }))
    }
    
    @ViewBuilder func tooltipView(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy) -> some View {
        
        let tooltipPosition = calculateTooltipPosition(tooltipInfo, geo: geo)
        let arrowPosition = calculateArrowPosition(tooltipInfo, geo: geo, tooltipPosition: tooltipPosition)
        
        ZStack(alignment: .top) {
            
            self.content(tooltipInfo.item)
                .getViewSize { continerSize in
                    self.tooltipSize = continerSize
                }
                .position(x: tooltipPosition.x, y: tooltipPosition.y + jumpOffset)
            
            ArrowShape(cornerRadius: 5)
                .fill(tooltipInfo.item.backgroundColor)
                .frame(width: tooltipInfo.item.arrowWidth, height: tooltipInfo.item.arrowWidth / 2)
                .rotationEffect(rotation(for: tooltipInfo.item.side))
                .position(x: arrowPosition.x, y: arrowPosition.y + jumpOffset)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .opacity(tooltipSize.isValidSize() && tooltipPosition != .zero ? 1.0 : 0.0)
    }
}

//MARK: - Animations
extension TooltipHolderView {
    
    private func startAnimation() {
        Task {@MainActor in
            await triggerJumpAnimation()
        }
    }
    
    private func triggerJumpAnimation(jumpHeight: CGFloat = -8) async {
        
        guard !isAnimating else { return }
        isAnimating = true
        
        jumpOffset = .zero
        try? await Task.sleep(seconds: 0.3)
        
        withAnimation(.easeOut(duration: 0.1)) {
            jumpOffset = jumpHeight
        }
        
        try? await Task.sleep(seconds: 0.1)
        
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
            jumpOffset = 0
        }
        
        try? await Task.sleep(seconds: 0.15)
        
        withAnimation(.easeOut(duration: 0.1)) {
            jumpOffset = jumpHeight * 0.7
        }
        
        try? await Task.sleep(seconds: 0.1)
        
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
            jumpOffset = 0
        }
        
        try? await Task.sleep(seconds: 0.25)
        
        isAnimating = false
    }
}

//MARK: - Helppers

extension TooltipHolderView {
    
    private func rotation(for side: TooltipSide) -> Angle {
        switch rtlSide(side) {
        case .bottom: return .degrees(0)
        case .top: return .degrees(180)
        case .trailing: return layoutDirection == .rightToLeft ? .degrees(-90) : .degrees(90)
        case .leading: return layoutDirection == .rightToLeft ? .degrees(90) : .degrees(-90)
        }
    }
    
    func rtlSide(_ side: TooltipSide) -> TooltipSide {
        switch side {
        case .bottom: return .bottom
        case .top: return .top
        case .trailing: return layoutDirection == .rightToLeft ? .leading : .trailing
        case .leading: return layoutDirection == .rightToLeft ? .trailing : .leading
        }
    }
}

//MARK: - Arrow Posstion
extension TooltipHolderView {
    private func calculateArrowPosition(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy, tooltipPosition: CGPoint) -> CGPoint {
        let item = tooltipInfo.item
        let targetFrame = tooltipInfo.targetFrame
        
        let arrowMargin: CGFloat = item.arrowWidth / 2
        
        let tooltipLeft = tooltipPosition.x - tooltipSize.width/2
        let tooltipRight = tooltipPosition.x + tooltipSize.width/2
        let tooltipTop = tooltipPosition.y - tooltipSize.height/2
        let tooltipBottom = tooltipPosition.y + tooltipSize.height/2
        
        var arrowX =  layoutDirection == .rightToLeft ? geo.size.width - targetFrame.midX : targetFrame.midX
        var arrowY = targetFrame.midY
        
        let fixedSide = rtlSide(item.side)
        switch fixedSide {
        case .top, .bottom:
            arrowY = fixedSide == .bottom ? tooltipTop : tooltipBottom
            
            let minX = tooltipLeft + arrowMargin
            let maxX = tooltipRight - arrowMargin
            arrowX = max(minX, min(arrowX, maxX))
            
        case .leading, .trailing:
            let side: TooltipSide = layoutDirection == .rightToLeft ? .trailing : .leading
            arrowX = fixedSide == side ? tooltipLeft : tooltipRight
            
            let minY = tooltipTop + arrowMargin
            let maxY = tooltipBottom - arrowMargin
            arrowY = max(minY, min(arrowY, maxY))
        }
        
        return CGPoint(x: arrowX, y: arrowY)
    }
}

//MARK: - ToolTip Posstion
extension TooltipHolderView {
    private func calculateTooltipPosition(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy) -> CGPoint {
        let item = tooltipInfo.item
        let targetFrame = tooltipInfo.targetFrame
        
        guard tooltipSize.isValidSize() else { return .zero }
        
        var xPos = targetFrame.midX
        var yPos = targetFrame.midY
        
        let spacing = item.spacing
        var arrowHeight = tooltipInfo.item.arrowWidth / 2
            arrowHeight = arrowHeight / 2
        
        switch rtlSide(item.side) {
        case .top:
            
            yPos = targetFrame.minY - tooltipSize.height / 2 - spacing - arrowHeight
            
        case .bottom:
            
            yPos = targetFrame.maxY + tooltipSize.height / 2 + spacing + arrowHeight
            
        case .trailing:
            
            xPos = targetFrame.minX - tooltipSize.width / 2 - spacing - arrowHeight
            xPos =  layoutDirection == .rightToLeft ? geo.size.width - xPos : xPos
            
        case .leading:
            xPos = targetFrame.maxX + tooltipSize.width / 2 + spacing + arrowHeight
            xPos =  layoutDirection == .rightToLeft ? geo.size.width - xPos : xPos
            
        }
        
        return fixTooltipPostions(tooltipInfo, geo: geo,xPos: xPos, yPos: yPos)
    }
    
    private func fixTooltipPostions(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy, xPos: CGFloat, yPos: CGFloat) -> CGPoint {
        let item = tooltipInfo.item
        
        let edgePadding: CGFloat = 10
        var xPos = xPos
        var yPos = yPos
        
        let leftEdge = xPos - tooltipSize.width/2
        let rightEdge = xPos + tooltipSize.width/2
        let topEdge = yPos - tooltipSize.height/2
        let bottomEdge = yPos + tooltipSize.height/2
        
        
        switch rtlSide(item.side) {
        case .top, .bottom:
            let isRTL = layoutDirection == .rightToLeft
            
            let shouldShiftLeft = (isRTL && leftEdge < edgePadding) || (!isRTL && rightEdge > geo.size.width)
            let shouldShiftRight = (isRTL && rightEdge > geo.size.width) || (!isRTL && leftEdge < edgePadding)
            
            if shouldShiftLeft {
                xPos = geo.size.width - (edgePadding + (tooltipSize.width / 2))
            } else if shouldShiftRight {
                xPos = edgePadding + (tooltipSize.width / 2)
            }
            
        case .trailing, .leading:
            if topEdge < safeAreaInsets.top {
                yPos = edgePadding + tooltipSize.height/2 + safeAreaInsets.top
            } else if bottomEdge > geo.size.height - safeAreaInsets.bottom {
                yPos = geo.size.height - edgePadding - tooltipSize.height/2 - safeAreaInsets.bottom
            }
        }
        
        return CGPoint(x: xPos, y: yPos)
    }
    
}
