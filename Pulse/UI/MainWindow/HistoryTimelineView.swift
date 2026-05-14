import SwiftUI

struct HistoryTimelineView: View {
    @EnvironmentObject var coordinator: RecordingCoordinator

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            Divider().background(Color.pulseTextTertiary.opacity(0.4))
            if coordinator.history.isEmpty {
                emptyState
            } else {
                scrollList
            }
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("No history yet")
                .font(.system(size: 13))
                .foregroundColor(.pulseTextTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var scrollList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(coordinator.history) { record in
                    HistoryRow(record: record)
                    Divider().background(Color.pulseTextTertiary.opacity(0.12))
                }
            }
        }
    }
}

private struct HistoryRow: View {
    let record: CachedTranscription

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(Self.timeFormatter.string(from: record.timestamp))
                    .font(.system(size: 11, weight: .light).monospacedDigit())
                    .foregroundColor(.pulseTextSecondary)
                Text(Self.dateFormatter.string(from: record.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.pulseTextTertiary)
            }
            .frame(width: 60, alignment: .trailing)

            Text(record.text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.pulseTextPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !record.syncedToConvex {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 10))
                    .foregroundColor(.pulseTextTertiary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
