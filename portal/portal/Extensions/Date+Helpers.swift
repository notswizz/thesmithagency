import Foundation

enum DateHelper: Sendable {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    private static let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    static func date(from string: String) -> Date? {
        formatter.date(from: string)
    }

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    static func display(_ dateString: String) -> String {
        guard let date = date(from: dateString) else { return dateString }
        return displayFormatter.string(from: date)
    }

    static func short(_ dateString: String) -> String {
        guard let date = date(from: dateString) else { return dateString }
        return shortFormatter.string(from: date)
    }

    static func dateRange(_ start: String, _ end: String) -> String {
        "\(short(start)) – \(short(end))"
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
