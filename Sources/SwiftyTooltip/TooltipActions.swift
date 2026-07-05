//
//  TooltipActions.swift
//  Mahly
//
//  Created by Abdulrahman Ameen Hariri on 26/03/2025.
//

import SwiftUI

enum TooltipActions {
    case register(_ context: String, id: String, frame: CGRect)
    case unregister(_ context: String, id: String)
}

struct TooltipActionEnvironment : Equatable, Hashable {
  
    typealias Action = ((_: TooltipActions) -> ())
    var action: Action
    let id: Int
    
    static func == (lhs: TooltipActionEnvironment, rhs: TooltipActionEnvironment) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func callAsFunction(_ action:TooltipActions) {
        self.action(action)
    }
}

extension EnvironmentValues {
    @Entry var tooltipAction: TooltipActionEnvironment?

    /// The set of tooltip contexts that are active in the current subtree.
    ///
    /// Each `.tooltip(context:)` modifier inserts its own context id into the
    /// inherited set rather than replacing it, so multiple tooltip contexts can
    /// be stacked on the same view hierarchy. A `TooltipTargetView` treats its
    /// context as active — and therefore observes its frame — only when the
    /// context id is a member of this set.
    @Entry var currentTooltipContexts: Set<String> = []
}

extension View {
    func onTooltipAction(id: Int,_ action: @escaping TooltipActionEnvironment.Action) -> some View {
        environment(\.tooltipAction, TooltipActionEnvironment(action: action, id:id))
    }

    /// Marks `context` as active for the subtree, preserving any contexts that
    /// were already active higher up the tree (e.g. from stacked `.tooltip`
    /// modifiers).
    func activateTooltipContext(_ context: String) -> some View {
        modifier(ActivateTooltipContextModifier(context: context))
    }
}

private struct ActivateTooltipContextModifier: ViewModifier {
    @Environment(\.currentTooltipContexts) private var currentTooltipContexts
    let context: String

    func body(content: Content) -> some View {
        content.environment(\.currentTooltipContexts, currentTooltipContexts.union([context]))
    }
}
