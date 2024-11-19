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

extension Date {
    /// Convert given date to DateComponents to use with EK lookups
    /// - Parameter calendar: System calendar
    /// - Returns: DateComponents to be used with EK values
    public func toComponents(calendar: Calendar = Calendar.current) -> DateComponents {
        calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
    }
}
