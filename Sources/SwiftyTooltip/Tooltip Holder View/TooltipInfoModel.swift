//
//  TooltipInfoModel.swift
//  Mahly
//
//  Created by Abdulrahman Ameen Hariri on 06/04/2025.
//
import SwiftUI

struct TooltipInfoModel<Item: TooltipItemConfigType>: Equatable & Identifiable {
    var id: String {
        item.id
    }
    
    var item: Item
    var targetFrame: CGRect
}
