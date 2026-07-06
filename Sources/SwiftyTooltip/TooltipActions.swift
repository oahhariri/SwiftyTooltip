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

struct TooltipActionEnvironment : Equatable, Hashable, @unchecked Sendable {

    typealias Action = ((_: TooltipActions) -> ())
    var action: Action
    let id: Int
    
    static func == (lhs: TooltipActionEnvironment, rhs: TooltipActionEnvironment) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func callAsFunction(_ action:TooltipActions) async {
        self.action(action)
    }
}

extension EnvironmentValues {
    /// The register/unregister handlers of every tooltip presenter that is active
    /// in the current subtree, keyed by the presenter's context id.
    ///
    /// This replaces the old single `tooltipAction: TooltipActionEnvironment?`
    /// and scalar `currentTooltipContext: String?`, both of which were single
    /// environment values that a nested presenter *overwrote* for the whole
    /// subtree. That overwrite was the bug: when two `.tooltip` presenters wrap
    /// the same content, the inner presenter replaced the shared value, so the
    /// outer presenter's targets either never activated *or* — once activated —
    /// sent their `register` action to the **inner** presenter's handler, which
    /// dropped it (`guard context == self.context.id`). Either way the outer
    /// context's tooltip never got a registered frame and never showed.
    ///
    /// By accumulating handlers into a per-context map, each presenter adds its
    /// own entry without clobbering the others. A `TooltipTargetView`:
    ///   * is **active** iff a handler exists for *its own* context id (so it only
    ///     starts frame observation when its own presenter is present — a target
    ///     never observes just because some *other* context is active), and
    ///   * routes its `register`/`unregister` to *its own* context's handler, so
    ///     the frame reaches the correct presenter.
    @Entry var tooltipActions: [String: TooltipActionEnvironment] = [:]
}

extension View {
    /// Registers `action` as the handler for `context`, merging it into any
    /// handlers already provided by presenters higher up the tree (e.g. from
    /// stacked `.tooltip` modifiers) instead of overwriting them.
    func onTooltipAction(context: String, id: Int, _ action: @escaping TooltipActionEnvironment.Action) -> some View {
        modifier(TooltipActionModifier(context: context,
                                       action: TooltipActionEnvironment(action: action, id: id)))
    }
}

private struct TooltipActionModifier: ViewModifier {
    @Environment(\.tooltipActions) private var tooltipActions
    let context: String
    let action: TooltipActionEnvironment

    func body(content: Content) -> some View {
        var merged = tooltipActions
        merged[context] = action
        return content.environment(\.tooltipActions, merged)
    }
}
