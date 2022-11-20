//
//  Date+Extensions.swift
//  ReDo
//
//  Created by Paul Traylor on 2021/09/16.
//

import Foundation

extension Date {
  public static var startOfDay: Date {
    return Calendar.current.startOfDay(for: .init())
  }
  public static var endOfDay: Date {
    return Calendar.current.startOfDay(for: .init()).addingTimeInterval(24 * 60 * 60)
  }
}
