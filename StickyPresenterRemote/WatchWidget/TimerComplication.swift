import SwiftUI
import WidgetKit

// MARK: - 컴플리케이션: 손목을 들 때마다 보는 남은 시간
// 시간은 시스템이 세는 타이머 글자라 매초 다시 그리지 않아도 줄어든다.
// 끝나는 시각에 한 장을 더 두어, 끝나면 "0:00" 으로 멈춘다.

struct TimerEntry: TimelineEntry {
    let date: Date
    let timer: WatchTimer?
}

struct TimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerEntry {
        TimerEntry(date: .now, timer: WatchTimer(id: UUID(), name: "15m", phase: nil, target: 900, isRunning: true,
                                                 endsAt: .now.addingTimeInterval(522), pausedRemaining: 522))
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entries().first!)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> Void) {
        completion(Timeline(entries: entries(), policy: .never))
    }

    private func entries() -> [TimerEntry] {
        let timer = WatchStore.load()?.timer
        var entries = [TimerEntry(date: .now, timer: timer)]
        if let end = timer?.endsAt, timer?.isRunning == true, end > .now {
            entries.append(TimerEntry(date: end, timer: timer))
        }
        return entries
    }
}

struct TimerComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TimerEntry

    var body: some View {
        if let timer = entry.timer {
            timerView(timer)
        } else {
            switch family {
            case .accessoryInline:
                Text(verbatim: "Remote Controller")
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Label { Text(verbatim: "Remote Controller") } icon: { Image(systemName: "timer") }
                        .font(.headline)
                        .widgetAccentable()
                    Text("돌고 있는 발표 타이머가 없어요")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            default:
                Image(systemName: "timer").font(.title3).widgetAccentable()
            }
        }
    }

    /// 돌고 있으면 시스템 타이머 글자, 멈췄거나 끝났으면 그 자리의 숫자.
    private func timeText(_ timer: WatchTimer) -> Text {
        if timer.isRunning, let end = timer.endsAt, end > entry.date {
            return Text(timerInterval: entry.date...end, countsDown: true)
        }
        return Text(verbatim: clockText(timer.remaining(at: entry.date)))
    }

    @ViewBuilder
    private func timerView(_ timer: WatchTimer) -> some View {
        let running = timer.isRunning && (timer.endsAt ?? .distantPast) > entry.date
        switch family {
        case .accessoryCircular:
            Gauge(value: timer.fractionLeft(at: entry.date)) {
                Image(systemName: "timer")
            } currentValueLabel: {
                timeText(timer)
                    .font(.system(.body, design: .rounded).weight(.semibold).monospacedDigit())
                    .minimumScaleFactor(0.5)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetAccentable()
        case .accessoryCorner:
            Image(systemName: running ? "timer" : "pause.fill")
                .font(.title3)
                .widgetAccentable()
                .widgetLabel { timeText(timer) }
        case .accessoryInline:
            timeText(timer)
        default:
            VStack(alignment: .leading, spacing: 0) {
                Text(timer.phase.map { "\(timer.name) · \($0)" } ?? timer.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                timeText(timer)
                    .font(.system(.title2, design: .rounded).weight(.bold).monospacedDigit())
                    .widgetAccentable()
                if !running {
                    Text(timer.remaining(at: entry.date) > 0 ? LocalizedStringKey("일시정지됨") : LocalizedStringKey("시간이 다 됐어요"))
                        .font(.caption2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

@main
struct TimerComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PresentationTimer", provider: TimerProvider()) { entry in
            TimerComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("발표 남은 시간")
        .description("Mac에서 도는 발표 타이머의 남은 시간을 보여 줍니다.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner, .accessoryInline])
    }
}
