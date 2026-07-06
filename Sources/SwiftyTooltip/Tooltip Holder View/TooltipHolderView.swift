//
//  TooltipHolderView.swift
//  Mahly
//
//  Created by Abdulrahman Ameen Hariri on 26/03/2025.
//

import SwiftUI

/// Carries the overlay's own origin, measured in `tooltipCoordinateSpace`, up to
/// `TooltipHolderView`. See `overlayOrigin` below for why it's needed.
private struct TooltipOverlayOriginKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { value = nextValue() }
}

struct TooltipHolderView<Item: TooltipItemConfigType, TooltipContent: View>: View {
    
    var tooltipInfo: TooltipInfoModel<Item>?
    
    let content: (Item) -> TooltipContent
    
    @Environment(\.layoutDirection) var layoutDirection
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @State private var tooltipSize: CGSize = .zero

    /// The overlay's own top-left, measured in `tooltipCoordinateSpace` (the space
    /// the target frame is measured in). It is the delta between the overlay's
    /// local geometry (`geo`, which — because the overlay ignores safe area —
    /// spans the window) and the coordinate space that `targetFrame` lives in.
    ///
    /// When `.tooltipContainer` sits at the window root these origins coincide, so
    /// this is `.zero` and nothing changes. When the container sits on an inset /
    /// pushed screen, the target frame is measured inset by the nav/safe-area while
    /// the overlay draws window-relative; subtracting this origin re-aligns the two
    /// spaces so the tooltip (and spotlight, and arrow) anchor under the target.
    @State private var overlayOrigin: CGPoint = .zero

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
        // Measure the delta between the space the TARGET frame is registered in
        // (`tooltipCoordinateSpace`, whose origin is the container view — inset by
        // the nav/safe-area on a pushed screen) and the space this overlay actually
        // RENDERS in (its `geo`, which — because the overlay ignores safe area —
        // spans the window, i.e. coincides with `.global`).
        //
        // Measuring only in `.named` returned ~`.zero` (the overlay resolves the
        // same nearest named space as the target, so they coincide there), which is
        // why the earlier attempt didn't move anything. The real mismatch is
        // named-vs-render: for a probe at the same point, `frame(in: .global)` and
        // `frame(in: .named(...))` differ by exactly the inset. `overlayOrigin` is
        // that delta (named − global); it is `.zero` at the window root (existing
        // tooltips unchanged) and equals the nav/status inset on a pushed screen —
        // the amount the sort tooltip was rendering shifted up by.
        .background(
            GeometryReader { proxy in
                let named = proxy.frame(in: .named(tooltipCoordinateSpace))
                let global = proxy.frame(in: .global)
                Color.clear.preference(
                    key: TooltipOverlayOriginKey.self,
                    value: CGPoint(x: named.minX - global.minX,
                                   y: named.minY - global.minY)
                )
            }
        )
        .onPreferenceChange(TooltipOverlayOriginKey.self) { newValue in
            overlayOrigin = newValue
        }
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
        // Convert the target frame from the space it was measured in
        // (`tooltipCoordinateSpace`, whose origin is the container view) into the
        // overlay's own local space (`geo`, which — because the overlay ignores
        // safe area — spans the window). `overlayOrigin` is the delta between the
        // two origins; subtracting it once here yields a frame already expressed in
        // `geo`-local coordinates, so every downstream calculation (spotlight,
        // tooltip position, arrow, emerge) runs UNCHANGED on a correctly-spaced
        // input. When the container sits at the window root the two origins
        // coincide, `overlayOrigin == .zero`, and `localTooltipInfo == tooltipInfo`
        // — i.e. byte-identical to the previous behaviour for every existing,
        // window-level tooltip. When the container sits on a pushed/inset screen,
        // the conversion cancels the nav/safe-area inset so the tooltip anchors
        // under the real target.
        let localTooltipInfo = tooltipInfo.convertingTargetFrame(by: overlayOrigin)

        ZStack(alignment: .top) {

            // ───────── VISUAL DEBUG OVERLAY (temporary) ─────────
            // RED   = raw target frame as registered (in whatever space it came in).
            // BLUE  = the same rect drawn at geo, i.e. where `.position` would put it.
            // Text  = key numbers so we can read the mismatch off the screen directly.
            debugOverlay(tooltipInfo, geo: geo)
            // ────────────────────────────────────────────────────

            backgroundView(localTooltipInfo)

            tooltipView(localTooltipInfo, geo: geo)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    /// Temporary on-screen debugger — reads off the numbers visually, no console.
    @ViewBuilder func debugOverlay(_ tooltipInfo: TooltipInfoModel<Item>, geo: GeometryProxy) -> some View {
        let raw = tooltipInfo.targetFrame
        // Where the real target actually is on screen, measured live in geo-space.
        ZStack(alignment: .topLeading) {
            // RED outline = the RAW registered target frame, drawn at its own coords.
            Rectangle()
                .stroke(Color.red, lineWidth: 3)
                .frame(width: raw.width, height: raw.height)
                .position(x: raw.midX, y: raw.midY)

            // GREEN dot = geo origin (0,0) marker, to see where this overlay's space starts.
            Circle().fill(Color.green).frame(width: 14, height: 14).position(x: 0, y: 0)

            // Text panel with the numbers.
            VStack(alignment: .leading, spacing: 2) {
                Text("geo.size \(Int(geo.size.width))×\(Int(geo.size.height))")
                Text("geo.global \(Int(geo.frame(in: .global).minX)),\(Int(geo.frame(in: .global).minY))")
                Text("RAW target x\(Int(raw.minX)) y\(Int(raw.minY)) \(Int(raw.width))×\(Int(raw.height))")
                Text("overlayOrigin \(Int(overlayOrigin.x)),\(Int(overlayOrigin.y))")
            }
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(6)
            .background(Color.black.opacity(0.8))
            .position(x: 130, y: 120)
        }
        .allowsHitTesting(false)
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

        let tooltipPosition = calculateTooltipPosition(tooltipInfo, geo: geo)
        let arrowPosition = calculateArrowPosition(tooltipInfo, geo: geo, tooltipPosition: tooltipPosition)

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
                .rotationEffect(rotation(for: tooltipInfo.item.side))
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
