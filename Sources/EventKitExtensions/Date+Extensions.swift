//
//  Date+Extensions.swift
//  ReDo
//
//  Created by Paul Traylor on 2021/09/16.
//

import Foundation

extension Date {
    public var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    public var endOfDay: Date {
        return Calendar.current.startOfDay(for: self).addingTimeInterval(24 * 60 * 60)
    }

}
