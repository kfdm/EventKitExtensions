//
//  CalendarStore.swift
//  ReDo
//
//  Created by Paul Traylor on 2021/06/27.
//

import EventKit
import Foundation
import SwiftUI
import os.log

open class CalendarStore: ObservableObject {
    var store: EKEventStore
    var logger: Logger

    public init(store: EKEventStore, logger: Logger) {
        self.store = store
        self.logger = logger
    }

    public func calendars() async -> [EKCalendar] {
        logger.info("fetching calendars")
        do {
            try await store.requestAccess(to: .reminder)
            return store.calendars(for: .reminder)
        } catch {
            logger.error("Error fetching calendars: \(error.localizedDescription)")
            return []
        }
    }

    public func refreshSourcesIfNecessary() {
        logger.info("refreshSourcesIfNecessary")
        store.refreshSourcesIfNecessary()
    }

    public var authorized: Bool {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .authorized:
            return true
        case .denied:
            return false
        case .notDetermined:
            store.requestAccess(to: .reminder) { (granted, error) in
                self.logger.debug("Granted access \(granted.description)")
            }
            return false
        case .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

// MARK: - EKCalendar Methods

extension CalendarStore {
    /// Fetch matching incomplete reminders
    /// - Parameters:
    ///   - calendar: Calendar to search
    ///   - start: The start date of the range of reminders fetched, or nil for all incomplete reminders before endDate.
    ///   - end: The end date of the range of reminders fetched, or nil for all incomplete reminders after startDate.
    /// - Returns: Return matching [EKReminder]
    public func incomplete(for calendar: EKCalendar, from start: Date? = nil, to end: Date? = nil) async -> [EKReminder] {
        logger.debug("Fetching incomplete for calendar \(calendar.title) from \(start.debugDescription) to \(end.debugDescription)")
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: start,
            ending: end,
            calendars: [calendar]
        )
        return await store.fetchReminders(matching: predicate)
    }

    /// Fetch matching completed reminders
    /// - Parameters:
    ///   - calendar: Calendar to search
    ///   - start: The start date of the range of reminders fetched, or nil for all completed reminders before endDate.
    ///   - end: The end date of the range of reminders fetched, or nil for all completed reminders after startDate.
    /// - Returns: Return matching [EKReminder]
    public func completed(for calendar: EKCalendar, from start: Date? = nil, to end: Date? = nil) async -> [EKReminder] {
        logger.debug("Fetching completed for calendar \(calendar.title) from \(start.debugDescription) to \(end.debugDescription)")
        let predicate = store.predicateForCompletedReminders(
            withCompletionDateStarting: start,
            ending: end,
            calendars: [calendar]
        )
        return await store.fetchReminders(matching: predicate)
    }

    public func completed(from start: Date? = nil, to end: Date? = nil) async -> [EKReminder] {
        logger.debug("Fetching completed from \(start.debugDescription) to \(end.debugDescription)")
        let predicate = store.predicateForCompletedReminders(
            withCompletionDateStarting: start,
            ending: end,
            calendars: []
        )
        return await store.fetchReminders(matching: predicate)
    }

    public func incomplete(from start: Date? = nil, to end: Date? = nil) async -> [EKReminder] {
        logger.debug("Fetching completed from \(start.debugDescription) to \(end.debugDescription)")
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: start,
            ending: end,
            calendars: []
        )
        return await store.fetchReminders(matching: predicate)
    }
}

extension CalendarStore {
    public func completed(on date: Date = Date()) async -> [EKReminder] {
        return await completed(from: date.startOfDay, to: date.endOfDay)
    }
    public func incomplete(for date: Date) async -> [EKReminder] {
        return await incomplete(from: date.startOfDay, to: date.endOfDay)
    }
}

// MARK: - EKReminder Methods

extension CalendarStore {
    public func new(title: String, for calendar: EKCalendar) {
        do {
            let reminder = EKReminder(eventStore: store)
            reminder.calendar = calendar
            reminder.title = title
            try store.save(reminder, commit: true)
        } catch {
            logger.error("Error creating reminder: \(error.localizedDescription)")
        }
    }

    public func new(for calendar: EKCalendar) -> EKReminder {
        let reminder = EKReminder(eventStore: store)
        reminder.calendar = calendar
        return reminder
    }

    public func complete(reminder: EKReminder) {
        reminder.completionDate = Date()
        try? store.save(reminder, commit: true)
    }

    public func undo(reminder: EKReminder) {
        reminder.completionDate = nil
        try? store.save(reminder, commit: true)
    }

}

extension CalendarStore {
    public func save(reminders: [EKReminder]) {
        logger.debug("Saving \(reminders.count) reminders")
        do {
            try reminders.forEach { try store.save($0, commit: false) }
            try store.commit()
        } catch {
            logger.error("Error saving reminders: \(error.localizedDescription)")
        }
    }

    public func save(_ reminder: EKReminder) {
        save(reminders: [reminder])
    }
}

extension CalendarStore {
    public func remove(reminders: [EKReminder]) {
        logger.debug("Removing \(reminders.count) reminders")
        do {
            try reminders.forEach { try store.remove($0, commit: false) }
            try store.commit()
        } catch {
            logger.error("Error removing reminders: \(error.localizedDescription)")
        }
    }
    public func remove(reminder: EKReminder) {
        try? store.remove(reminder, commit: true)
    }
}
