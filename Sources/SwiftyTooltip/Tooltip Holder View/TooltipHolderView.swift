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
    /// Progress of the "emerge from target" animation: 0 = collapsed onto the
    /// target, 1 = resting at full size/position.
    @State private var appearProgress: CGFloat = 0
    
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
        // The target frame is now measured in `.global` (see TooltipTargetView),
        // which is the same window-absolute space this overlay renders in, so no
        // coordinate conversion is needed here — the frame is used as-is.
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
            handelDissmissAction(tooltipInfo)
            
        }
        .simultaneousGesture(DragGesture(minimumDistance: 15, coordinateSpace: .local).onChanged({ _ in
            handelDissmissAction(tooltipInfo)
        }))
    }
    
    @ViewBuilder func tooltipView(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy) -> some View {

        // Resolve the side ONCE and thread it through position, arrow, and arrow
        // rotation so all three stay consistent after an off-screen flip.
        let side = effectiveSide(tooltipInfo, geo: geo)
        let tooltipPosition = calculateTooltipPosition(tooltipInfo, geo: geo, side: side)
        let arrowPosition = calculateArrowPosition(tooltipInfo, geo: geo, side: side, tooltipPosition: tooltipPosition)

        let emerge = emergeTransform(tooltipInfo, geo: geo, tooltipPosition: tooltipPosition)

        ZStack(alignment: .top) {

            self.content(tooltipInfo.item)
                .getViewSize { continerSize in
                    self.tooltipSize = continerSize
                }
                // Emerge-from-target: the bubble's CENTER is interpolated from the
                // target's center to the resting position, and it scales up from a
                // small size — anchored at `.center` so scaling never drags it into
                // a corner. `emerge.center` is already in this `.position` space, so
                // it lands on the target in both LTR and RTL.
                .scaleEffect(emerge.scale, anchor: .center)
                .opacity(emerge.opacity)
                .position(x: emerge.center.x,
                          y: emerge.center.y + jumpOffset)

            ArrowShape(cornerRadius: 5)
                .fill(tooltipInfo.item.backgroundColor)
                .frame(width: tooltipInfo.item.arrowWidth, height: tooltipInfo.item.arrowWidth / 2)
                .rotationEffect(rotation(for: side))
                .position(x: arrowPosition.x, y: arrowPosition.y + jumpOffset)
                .opacity(emerge.arrowOpacity)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .opacity(tooltipSize.isValidSize() && tooltipPosition != .zero ? 1.0 : 0.0)
    }
}

//MARK: - Emerge-from-target transform
extension TooltipHolderView {

    /// The resolved bubble center / scale / opacity for the emerge-from-target
    /// animation at the current `appearProgress`. For items that don't use the
    /// emerge style this returns identity values (center == resting position,
    /// scale 1, fully opaque) so the tooltip renders exactly as before.
    struct EmergeTransform {
        var center: CGPoint
        var scale: CGFloat
        var opacity: CGFloat
        var arrowOpacity: CGFloat
    }

    func emergeTransform(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy, tooltipPosition: CGPoint) -> EmergeTransform {
        // Identity for the jump style, or before the bubble has been measured: the
        // center is simply the resting position and everything is full-size/opaque.
        let identity = EmergeTransform(center: tooltipPosition, scale: 1, opacity: 1, arrowOpacity: 1)
        guard tooltipInfo.item.appearanceAnimation.includesEmerge else { return identity }
        guard tooltipSize.isValidSize(), tooltipPosition != .zero else { return identity }

        let progress = max(0, min(1, appearProgress))
        let targetFrame = tooltipInfo.targetFrame

        // Target center expressed in the SAME `.position` space as `tooltipPosition`.
        // The existing position math leaves x un-mirrored for top/bottom sides but
        // mirrors it (geo.width - x) for leading/trailing sides in RTL; we mirror
        // the target center the same way so it coincides with the on-screen target
        // in both LTR and RTL. (Using the raw, un-mirrored `targetFrame.midX`
        // directly was the bug that made the bubble emerge from a screen corner.)
        let targetCenter = targetCenterInPositionSpace(tooltipInfo, geo: geo)

        // Interpolate the bubble center from the target (progress 0) to the resting
        // position (progress 1). At progress 0 the small bubble sits on the target.
        let cx = targetCenter.x + (tooltipPosition.x - targetCenter.x) * progress
        let cy = targetCenter.y + (tooltipPosition.y - targetCenter.y) * progress

        // Start roughly the target's size so it looks like it grows out of it.
        let rawStartScale = min(targetFrame.height / tooltipSize.height,
                                targetFrame.width / tooltipSize.width)
        let startScale = min(max(rawStartScale.isFinite ? rawStartScale : 0.2, 0.05), 0.9)
        let scale = startScale + (1 - startScale) * progress

        // Fade the content in quickly, and the arrow slightly later so it doesn't
        // float detached while the body is still collapsed onto the target.
        let opacity = min(1, progress * 2.2)
        let arrowOpacity = max(0, min(1, (progress - 0.35) / 0.5))

        return EmergeTransform(center: CGPoint(x: cx, y: cy),
                               scale: scale,
                               opacity: opacity,
                               arrowOpacity: arrowOpacity)
    }

    /// The target's center point, mapped into the same coordinate space that
    /// `.position` uses to place the tooltip.
    ///
    /// Ground truth: `calculateArrowPosition` positions the arrow at the target's
    /// x with `layoutDirection == .rightToLeft ? geo.width - targetFrame.midX
    /// : targetFrame.midX` for *every* side, and the arrow renders correctly in
    /// both directions. So the target-center x in `.position` space is that same
    /// mirrored value — for all sides, not just the horizontal ones. (Mirroring
    /// only top/bottom sides in RTL, or leaving x raw, was the RTL x bug.)
    private func targetCenterInPositionSpace(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy) -> CGPoint {
        let targetFrame = tooltipInfo.targetFrame
        let x = layoutDirection == .rightToLeft ? geo.size.width - targetFrame.midX
                                                 : targetFrame.midX
        return CGPoint(x: x, y: targetFrame.midY)
    }
}

//MARK: - Animations
extension TooltipHolderView {

    private func startAnimation() {
        Task {@MainActor in
            await triggerAppearanceAnimation()
        }
    }

    private func triggerAppearanceAnimation() async {
        let style = tooltipInfo?.item.appearanceAnimation ?? .jump

        if style.includesEmerge {
            await triggerEmergeAnimation()
        } else {
            // No emerge → the tooltip is shown at full size immediately.
            appearProgress = 1
        }

        if style.includesJump {
            await triggerJumpAnimation()
        }
    }

    private func triggerEmergeAnimation() async {
        guard !isAnimating else { return }
        isAnimating = true

        // Reset to collapsed-on-target, then spring out to full size/position.
        appearProgress = 0
        // Let layout settle (tooltipSize measured) before springing out.
        try? await Task.sleep(seconds: 0.02)
        withAnimation(.interpolatingSpring(stiffness: 260, damping: 22)) {
            appearProgress = 1
        }
        try? await Task.sleep(seconds: 0.35)

        isAnimating = false
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
    private func calculateArrowPosition(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy, side: TooltipSide, tooltipPosition: CGPoint) -> CGPoint {
        let item = tooltipInfo.item
        let targetFrame = tooltipInfo.targetFrame

        let arrowMargin: CGFloat = item.arrowWidth / 2

        let tooltipLeft = tooltipPosition.x - tooltipSize.width/2
        let tooltipRight = tooltipPosition.x + tooltipSize.width/2
        let tooltipTop = tooltipPosition.y - tooltipSize.height/2
        let tooltipBottom = tooltipPosition.y + tooltipSize.height/2

        var arrowX =  layoutDirection == .rightToLeft ? geo.size.width - targetFrame.midX : targetFrame.midX
        var arrowY = targetFrame.midY

        let fixedSide = rtlSide(side)
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
    /// Computes the tooltip center for a specific `side` (already RTL-resolved via
    /// `rtlSide` inside). The `side` is resolved once by `effectiveSide` in
    /// `tooltipView` and threaded here + into the arrow so they stay consistent
    /// after an off-screen flip.
    private func calculateTooltipPosition(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy, side: TooltipSide) -> CGPoint {
        guard tooltipSize.isValidSize() else { return .zero }
        let raw = rawTooltipPosition(tooltipInfo, geo: geo, side: side)
        return fixTooltipPostions(tooltipInfo, geo: geo, side: side, xPos: raw.x, yPos: raw.y)
    }

    /// The tooltip center for `side` BEFORE the on-screen edge clamp
    /// (`fixTooltipPostions`). Shared by the real placement and by the off-screen
    /// fit check so both use IDENTICAL RTL handling — the fit check can never
    /// disagree with where the tooltip actually renders.
    private func rawTooltipPosition(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy, side: TooltipSide) -> CGPoint {
        let item = tooltipInfo.item
        let targetFrame = tooltipInfo.targetFrame

        var xPos = targetFrame.midX
        var yPos = targetFrame.midY

        let spacing = item.spacing
        var arrowHeight = tooltipInfo.item.arrowWidth / 2
            arrowHeight = arrowHeight / 2

        switch rtlSide(side) {
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

        return CGPoint(x: xPos, y: yPos)
    }
    
    private func fixTooltipPostions(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy, side: TooltipSide, xPos: CGFloat, yPos: CGFloat) -> CGPoint {
        let edgePadding: CGFloat = 10
        var xPos = xPos
        var yPos = yPos

        let leftEdge = xPos - tooltipSize.width/2
        let rightEdge = xPos + tooltipSize.width/2
        let topEdge = yPos - tooltipSize.height/2
        let bottomEdge = yPos + tooltipSize.height/2


        switch rtlSide(side) {
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

//MARK: - Off-screen side resolution
extension TooltipHolderView {

    /// Chooses the side the tooltip is actually drawn on so it stays on screen.
    ///
    /// Priority, per the requested `item.side`:
    ///   1. the requested side,
    ///   2. its opposite on the same axis (bottom↔top, leading↔trailing),
    ///   3. the two sides on the perpendicular axis.
    /// The first candidate whose full tooltip rect fits within the safe-area-inset
    /// bounds wins. If none fit, the requested side is kept (falls back to the
    /// existing edge-clamp behaviour), so this never makes a previously-shown
    /// tooltip disappear — it only improves off-screen cases.
    ///
    /// `item.side` is the *logical* side; all candidates below are logical too and
    /// get RTL-resolved downstream, so the flip is correct in LTR and RTL.
    func effectiveSide(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy) -> TooltipSide {
        let requested = tooltipInfo.item.side
        guard tooltipSize.isValidSize() else { return requested }

        for candidate in candidateSides(for: requested) {
            if tooltipFits(tooltipInfo, geo: geo, side: candidate) {
                return candidate
            }
        }
        return requested
    }

    /// Candidate sides in priority order: requested → opposite → perpendicular pair.
    private func candidateSides(for side: TooltipSide) -> [TooltipSide] {
        switch side {
        case .top:      return [.top, .bottom, .leading, .trailing]
        case .bottom:   return [.bottom, .top, .leading, .trailing]
        case .leading:  return [.leading, .trailing, .top, .bottom]
        case .trailing: return [.trailing, .leading, .top, .bottom]
        }
    }

    /// True if the tooltip, placed on `side`, fits within the visible bounds on
    /// the axis that `side` controls — i.e. a `.bottom` tooltip must not run past
    /// the bottom safe-area edge, a `.top` past the top, a horizontal side past the
    /// left/right window edge, etc.
    ///
    /// It uses `rawTooltipPosition` — the SAME function the real placement uses —
    /// so the fit check inherits the exact RTL handling of the actual render (for
    /// horizontal sides the x is computed un-mirrored then mirrored by geo width;
    /// re-deriving that by hand here is what would go wrong in RTL). We then test
    /// the resulting bubble rect's edge on the side's own axis. The perpendicular
    /// axis is left to the existing clamp in `fixTooltipPostions`.
    private func tooltipFits(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy, side: TooltipSide) -> Bool {
        let center = rawTooltipPosition(tooltipInfo, geo: geo, side: side)

        let top = center.y - tooltipSize.height / 2
        let bottom = center.y + tooltipSize.height / 2
        let left = center.x - tooltipSize.width / 2
        let right = center.x + tooltipSize.width / 2

        // `rtlSide(side)` is the *visual* side after RTL resolution. The bubble
        // extends away from the target on that visual side, so check that axis.
        switch rtlSide(side) {
        case .top:
            return top >= safeAreaInsets.top
        case .bottom:
            return bottom <= geo.size.height - safeAreaInsets.bottom
        case .trailing, .leading:
            // Horizontal placement: the mirrored center already encodes which
            // physical edge the bubble sits against, so just verify both x edges
            // are on screen.
            return left >= 0 && right <= geo.size.width
        }
    }
}

extension TooltipHolderView {
    func handelDissmissAction(_ tooltipInfo: TooltipInfoModel<Item>) {
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
}
