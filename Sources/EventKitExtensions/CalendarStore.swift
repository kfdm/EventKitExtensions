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
    var store : EKEventStore
    var logger : Logger

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

    public func refreshSourcesIfNecessary() async {
        logger.info("refreshSourcesIfNecessary")
        store.refreshSourcesIfNecessary()
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
        let predicate = store.predicateForIncompleteReminders(withDueDateStarting: start, ending: end, calendars: [calendar])
        return await store.fetchReminders(matching: predicate)
    }

    /// Fetch matching completed reminders
    /// - Parameters:
    ///   - calendar: Calendar to search
    ///   - start: The start date of the range of reminders fetched, or nil for all completed reminders before endDate.
    ///   - end: The end date of the range of reminders fetched, or nil for all completed reminders after startDate.
    /// - Returns: Return matching [EKReminder]
    public func completed(for calendar: EKCalendar, from start: Date? = nil, to end: Date? = nil) async
        -> [EKReminder]
    {
        let predicate = store.predicateForCompletedReminders(
            withCompletionDateStarting: start, ending: end, calendars: [calendar])
        return await store.fetchReminders(matching: predicate)
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
            objectWillChange.send()
        } catch {
            logger.error("Error creating reminder: \(error.localizedDescription)")
        }
    }
    public func complete(reminder: EKReminder) {
        reminder.completionDate = Date()
        try? store.save(reminder, commit: true)
        objectWillChange.send()
    }
    public func remove(reminder: EKReminder) {
        try? store.remove(reminder, commit: true)
        objectWillChange.send()
    }
    public func undo(reminder: EKReminder) {
        reminder.completionDate = nil
        try? store.save(reminder, commit: true)
        objectWillChange.send()
    }
    public func remove(reminders: [EKReminder]) {
        logger.debug("Removing \(reminders.count) reminders")
        do {
            try reminders.forEach { try store.remove($0, commit: false) }
            try store.commit()
        } catch {
            logger.error("Error removing reminders: \(error.localizedDescription)")
        }
        objectWillChange.send()
    }
}
