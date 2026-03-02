import SwiftUI
import MapKit

struct AddressSearchField: View {
    let label: String
    @Binding var text: String

    @State private var completer = AddressCompleter()
    @State private var showSuggestions = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundStyle(.textTertiary)

            TextField(label, text: $text)
                .font(.system(size: 15))
                .padding(16)
                .background(Color.surfaceElevated)
                .foregroundStyle(.textPrimary)
                .tint(.brand)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isFocused && !completer.results.isEmpty ? Color.brand.opacity(0.4) : Color.borderSubtle)
                )
                .focused($isFocused)
                .onChange(of: text) { _, newValue in
                    completer.search(newValue)
                    showSuggestions = isFocused && !newValue.isEmpty
                }
                .onChange(of: isFocused) { _, focused in
                    showSuggestions = focused && !text.isEmpty && !completer.results.isEmpty
                }

            if showSuggestions && !completer.results.isEmpty {
                VStack(spacing: 0) {
                    ForEach(completer.results.prefix(4), id: \.self) { result in
                        Button {
                            text = [result.title, result.subtitle]
                                .filter { !$0.isEmpty }
                                .joined(separator: ", ")
                            showSuggestions = false
                            isFocused = false
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.brand)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.textPrimary)
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.textTertiary)
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)

                        if result != completer.results.prefix(4).last {
                            Divider().overlay(Color.borderSubtle)
                        }
                    }
                }
                .background(Color.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.borderSubtle))
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeOut(duration: 0.15), value: completer.results.count)
            }
        }
    }
}

@Observable
final class AddressCompleter: NSObject, MKLocalSearchCompleterDelegate {
    var results: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        completer.resultTypes = .address
        super.init()
        completer.delegate = self
    }

    func search(_ query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }
        completer.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}
