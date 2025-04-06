//
//  FirstAppearViewModifier.swift
//  SwiftyTooltip
//
//  Created by Abdulrahman Ameen Hariri on 06/04/2025.
//

import Foundation
import SwiftUI

internal class FirstAppearViewModel: ObservableObject {
      var firstAppear:Bool = true
}

internal struct FirstAppearViewModifier : ViewModifier {
     
    @StateObject private var model: FirstAppearViewModel = .init()
    
    var onFirstAppear: (()async -> ())?
    
    func body(content: Content) -> some View {
        content
        .task {
            guard model.firstAppear else{return}
            model.firstAppear = false
            
            await onFirstAppear?()
        }
    }
     
}

internal extension View {
    func onFirstAppear(_ task: (()async -> ())?) -> some View {
        self.modifier(FirstAppearViewModifier(onFirstAppear: task))
    }
}

