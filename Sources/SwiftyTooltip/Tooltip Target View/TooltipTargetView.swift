//
//  TooltipTargetView.swift
//  Mahly
//
//  Created by Abdulrahman Ameen Hariri on 26/03/2025.
//

import SwiftUI

@globalActor actor TooltipTargetBackgroundActor: GlobalActor {
    static var shared = TooltipTargetBackgroundActor()
}

struct TooltipTargetView<Content: View, Context: TooltipContextType>: View {
    
    let context: Context
    let id: String
    @Environment(\.tooltipActions) var tooltipActions

    @ViewBuilder var content: () -> Content

    /// The handler of *this target's own* presenter, if that presenter is present
    /// in the subtree. Nil means no matching `.tooltip(context:)` is active above
    /// this target, so it stays in the cheap `content()` branch and does no frame
    /// observation — a target never observes just because some *other* context is
    /// active in the same subtree.
    private var tooltipAction: TooltipActionEnvironment? {
        tooltipActions[context.id]
    }

    public var body: some View {
        if let tooltipAction {
            mainView(tooltipAction)
        } else {
            content()
        }
    }

    func mainView(_ tooltipAction: TooltipActionEnvironment) -> some View {
        // `contextId`, `targetId` and `tooltipAction` are all captured *by value*
        // into each `@Sendable` Task closure below: String values and a Sendable
        // action wrapper. Nothing mutable is shared across the actor hop. The only
        // actor-isolated state (the `targets` dictionary) is mutated exclusively
        // inside the presenter's own `Task {@TooltipsBackgroundActor in … }` in
        // `handelActions` — never from here.
        let contextId = context.id
        let targetId = id
        return content()
            // Measure the target in `.global` (window/scene-absolute), NOT in the
            // container's named space. The tooltip overlay is injected by
            // SwiftUIOverlayContainer as a window-spanning, safe-area-ignoring
            // overlay, so it renders in global space (verified on device:
            // geo.frame(in: .global) == (0,0), geo.size == full window). A target
            // measured in the container's `.named` space is inset by the
            // nav/safe-area when the container sits on a pushed screen, so its y
            // came out `inset` too small and the tooltip rendered shifted up.
            // Measuring in `.global` puts the target in the same space the overlay
            // renders in, for every container level — window-root containers are
            // unchanged (there `.named ≈ .global`) and pushed-screen containers are
            // fixed. (X is likewise more correct: the RTL mirror uses the overlay's
            // full window width, which matches global, not the inset named space.)
            .getViewFrame(coordinateSpace: .global) { frame in
                Task {@TooltipTargetBackgroundActor in
                    await tooltipAction(.register(contextId, id: targetId, frame: frame))
                }
            }
            .onDisappear {
                Task {@TooltipTargetBackgroundActor in
                    await tooltipAction(.unregister(contextId, id: targetId))
                }
            }
            .uiKitViewControllerLifeCycle { lifecycle in
                guard lifecycle == .onDeinit else { return }
                Task {@TooltipTargetBackgroundActor in
                    await tooltipAction(.unregister(contextId, id: targetId))
                }
            }
    }
}
