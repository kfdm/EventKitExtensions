//
//  EventKit+Extensions.swift
//  ReDo
//
//  Created by Paul Traylor on 2021/06/27.
//

import EventKit
import Foundation
import SwiftUI

extension EKCalendar: Identifiable {
    public var color: Color {
        get { Color(cgColor) }
        // TODO: Figure out why this doesn't seem to work with simulator/previews
        set { cgColor = newValue.cgColor }
    }
}

extension EKReminder: Identifiable {
    public var hasUrl: Bool { nil != url }
}

extension EKSource: Identifiable {
    public var id: String {
        return sourceIdentifier
    }
}

extension EKRecurrenceRule: Identifiable {
    public var id: String {
        return calendarIdentifier
    }
}

// MARK: EKReminder

extension EKEventStore {
    public func fetchReminders(matching predicate: NSPredicate) async throws -> [EKReminder]? {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<[EKReminder]?, Error>) in
            self.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders)
            }
        })
    }
    public func fetchReminders(matching predicate: NSPredicate) async -> [EKReminder] {
        do {
            return try await fetchReminders(matching: predicate) ?? []
        } catch {
            return []
        }
    }
}

// MARK: EKEvent

extension EKEvent: Identifiable {

}

extension EKEventStore {
    public func fetchEvent(matching predicate: NSPredicate) async throws -> [EKEvent]? {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<[EKEvent]?, Error>) in
            continuation.resume(returning: self.events(matching: predicate))
        })
    }
    public func fetchEvent(matching predicate: NSPredicate) async -> [EKEvent] {
        do {
            return try await fetchEvent(matching: predicate) ?? []
        } catch {
            return []
        }
    }
}

extension View {
    func onReceive(
        _ name: Notification.Name,
        center: NotificationCenter = .default,
        object: AnyObject? = nil,
        perform action: @escaping (Notification) async -> Void
    ) -> some View {
        self.onReceive(center.publisher(for: name)) { output in
            Task { await action(output) }
        }
    }

    public func onEventStoreChanged(action: @escaping () async -> Void) -> some View {
        self
            .onReceive(.EKEventStoreChanged) { notification in
                print("Received \(notification.debugDescription)")
                await action()
            }
    }
}

extension EKEventStore {
    public func factoryCalendar(for type: EKEntityType) -> EKCalendar {
        let calendar = EKCalendar(for: type, eventStore: self)
        calendar.title = "Factory: Calendar"
        calendar.cgColor = CGColor(red: 128, green: 0, blue: 128, alpha: 1)
        return calendar
    }
    public func factoryReminder(title: String = "Factory Reminder", url: String? = nil, due: Date? = nil, recurrence: EKRecurrenceFrequency? = nil, priority: Int = 5, location: String? = nil)
        -> EKReminder
    {
        let reminder = EKReminder(eventStore: self)
        reminder.calendar = self.factoryCalendar(for: .reminder)
        reminder.title = title

        if let urlstring = url {
            reminder.url = URL(string: urlstring)
        }
        reminder.dueDateComponents = due?.toComponents()

        if let frequence = recurrence {
            reminder.addRecurrenceRule(.init(recurrenceWith: frequence, interval: 1, end: nil))
        }

        reminder.location = "Some Location"
        reminder.priority = priority

        return reminder
    }
}
