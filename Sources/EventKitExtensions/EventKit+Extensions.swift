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
        Color(cgColor)
    }
}

extension EKReminder: Identifiable {

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
