//
//  DF.swift
//  Home Reminders
//
//  Created by Lawrence H. Schoch on 9/24/25.
//

import Foundation

class DF {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
