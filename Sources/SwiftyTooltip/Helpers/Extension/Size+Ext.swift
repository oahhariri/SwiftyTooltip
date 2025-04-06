//
//  Size+Ext.swift
//  Mahly
//
//  Created by Abdulrahman Ameen Hariri on 06/04/2025.
//

import Foundation

internal extension CGSize {
    func isValidSize() -> Bool {
        width > 0 && height > 0
    }
}
