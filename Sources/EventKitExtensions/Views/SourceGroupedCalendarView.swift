//
//  SwiftUIView.swift
//  
//
//  Created by Paul Traylor on 2022/11/20.
//

import SwiftUI
import EventKit


struct CalendarGroup {
    var source: String
    var calendars: [EKCalendar]
}

public struct SourceGroupedCalendarView<ContentView: View>: View {
    private var groups: [CalendarGroup]
    private var content: (EKCalendar) -> ContentView

    public init(groups: [EKCalendar], content: @escaping (EKCalendar) -> ContentView) {
        let grouped = Dictionary.init(grouping: groups) { $0.source!.title }
        let mapped = grouped.map { CalendarGroup(source: $0, calendars: $1) }
        self.groups = mapped.sorted { $0.source > $1.source }
        self.content = content
    }

    public var body: some View {
        List {
            ForEach(groups, id: \.source) { group in
                Section(group.source) {
                    ForEach(group.calendars.sorted(by: \.title)) { calendar in
                        content(calendar)
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}
