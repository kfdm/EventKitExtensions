//
//  EventKit+NSItemProvider.swift
//
//
//  Created by Paul Traylor on 2022/12/18.
//

import EventKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    public static let reminder = UTType.url
}

extension EKReminder: NSItemProviderWriting {
    public static var writableTypeIdentifiersForItemProvider: [String] {
        [
            UTType.reminder.identifier
        ]
    }

    public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping @Sendable (Data?, Error?) -> Void) -> Progress? {
        switch typeIdentifier {
        case UTType.reminder.identifier:
            var url = URLComponents(string: "reminder://reminder")!
            url.queryItems = [
                URLQueryItem(name: "calendar", value: calendar.calendarIdentifier),
                URLQueryItem(name: "reminder", value: calendarItemIdentifier),
            ]
            completionHandler(url.url!.absoluteString.data(using: .utf8), nil)
            return .discreteProgress(totalUnitCount: 100)
        default:
            fatalError("Unknown type \(typeIdentifier)")
        }
    }
}

extension CalendarStore {
    public func reminder(from url: URL) async -> EKReminder? {
        let lookup = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let id = lookup?.queryItems?.first { $0.name == "reminder" }?.value
        return await reminder(for: id!)
    }
}

public struct CalendarDropDelegate: DropDelegate {
    public init(store: CalendarStore, calendar: EKCalendar) {
        self.store = store
        self.calendar = calendar
    }
    public func performDrop(info: DropInfo) -> Bool {
        guard info.hasItemsConforming(to: [.reminder]) else {
            print("no confirming items")
            return false
        }

        for item in info.itemProviders(for: [.reminder]) {
            _ = item.loadObject(ofClass: URL.self) { url, error in
                guard error == nil else { return print(error.debugDescription) }
                guard let url = url else { return }
                switch url.scheme {
                case "reminder":
                    Task {
                        guard let reminder = await store.reminder(from: url) else { return }
                        reminder.calendar = calendar
                        store.save(reminders: [reminder])
                    }
                default:
                    print("Unknown URL Scheme")
                }
            }
        }
        return true
    }

    var store: CalendarStore
    var calendar: EKCalendar
}
