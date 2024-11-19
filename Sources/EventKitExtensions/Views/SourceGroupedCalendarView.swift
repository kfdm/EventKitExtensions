//
//  SwiftUIView.swift
//
//
//  Created by Paul Traylor on 2022/11/20.
//

import EventKit
import SwiftUI

struct CalendarGroup {
    var source: String
    var calendars: [EKCalendar]
}

public struct SourceGroupedCalendarView<Header: View, Footer: View, ContentView: View>: View {
    private let groups: [CalendarGroup]
    private let content: (EKCalendar) -> ContentView

    private let header: Header?
    private let footer: Footer?

    public init(
        groups: [EKCalendar],
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder footer: @escaping () -> Footer,
        @ViewBuilder content: @escaping (EKCalendar) -> ContentView
    ) {
        let grouped = Dictionary.init(grouping: groups) { $0.source!.title }
        let mapped = grouped.map { CalendarGroup(source: $0, calendars: $1) }
        self.groups = mapped.sorted { $0.source > $1.source }
        self.header = header()
        self.footer = footer()
        self.content = content
    }

    public var body: some View {
        List {
            self.header
            ForEach(groups, id: \.source) { group in
                Section(group.source) {
                    ForEach(group.calendars.sorted(by: \.title)) { calendar in
                        content(calendar)
                    }
                }
            }
            self.footer
        }

        #if os(iOS)
            .listStyle(GroupedListStyle())
        #endif
    }
}

extension SourceGroupedCalendarView {
    public init(
        groups: [EKCalendar],
        @ViewBuilder footer: @escaping () -> Footer,
        @ViewBuilder content: @escaping (EKCalendar) -> ContentView
    ) where Header == EmptyView {
        self.init(
            groups: groups,
            header: { EmptyView() },
            footer: footer,
            content: content
        )
    }

    public init(
        groups: [EKCalendar],
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping (EKCalendar) -> ContentView
    ) where Footer == EmptyView {
        self.init(
            groups: groups,
            header: header,
            footer: { EmptyView() },
            content: content
        )
    }

    public init(
        groups: [EKCalendar],
        @ViewBuilder content: @escaping (EKCalendar) -> ContentView
    ) where Header == EmptyView, Footer == EmptyView {
        self.init(
            groups: groups,
            header: { EmptyView() },
            footer: { EmptyView() },
            content: content
        )
    }
}
