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
    var id: Int = 0
    
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
    @Entry var currentTooltipContext: String?
}

extension View {
    func onTooltipAction(_ action: @escaping TooltipActionEnvironment.Action) -> some View {
        environment(\.tooltipAction, TooltipActionEnvironment(action: action))
    }
}
