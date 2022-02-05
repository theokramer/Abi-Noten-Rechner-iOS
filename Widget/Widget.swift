//
//  Widget.swift
//  Widget
//
//  Created by Theo Kramer on 30.07.21.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent(), note: "1.0")
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context,
                     completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), configuration: configuration, note: "1.0")
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context,
                     completion: @escaping (Timeline<Entry>) -> Void) {
        var entries: [SimpleEntry] = []
        var note = ""
        if let userDefaults = UserDefaults(suiteName: "group.notenRechner.widgetcache") {
            note = userDefaults.string(forKey: "text") ?? ""
        }
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration, note: note)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let note: String
}

@main
struct LastGradeWidget: Widget {
    let kind: String = "Widget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Letzter Notenschnitt")
        .description("Dieses Widget zeigt deinen zuletzt gespeicherten Noten Schnitt an")
    }
}

struct WidgetEntryView: View {
    var entry: Provider.Entry
    var body: some View {
        Text(entry.note).font(.title)
    }
}

struct Widget_Previews: PreviewProvider {
    static var previews: some View {
        WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), note: "1.0"))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
