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
            .getViewFrame(coordinateSpace: .named(tooltipCoordinateSpace)) { frame in
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
