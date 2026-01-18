import SwiftUI
import Foundation
import Combine
import MapKit

final class RecommendationViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var output: String = ""
    @Published var isLoading: Bool = false

    @Published var aiInstructions: String = ""
    @Published var dataFileContents: String = ""
    @Published var locationsFileContents: String = ""

    // Service should be injectable; provide a default
    private let service: RecommendationService

    init(service: RecommendationService = RecommendationService(apiKey: "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")) {
        self.service = service
    }

    // File locations
    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    private var aiInstructionsBundleURL: URL? { Bundle.main.url(forResource: "AIinstructions", withExtension: "txt") }
    private var dataBundleURL: URL? { Bundle.main.url(forResource: "data", withExtension: "txt") }
    private var locationsBundleURL: URL? { Bundle.main.url(forResource: "locations", withExtension: "txt") }
    private var aiInstructionsFileURL: URL { documentsURL.appendingPathComponent("AIinstructions.txt") }
    private var dataFileURL: URL { documentsURL.appendingPathComponent("data.txt") }
    private var locationsFileURL: URL { documentsURL.appendingPathComponent("locations.txt") }

    func onAppear() {
        aiInstructions = readAIInstructions()
        dataFileContents = readDataFile()
        locationsFileContents = readLocationsFile()
        if !isLoading && output.isEmpty {
            fetch()
        }
    }

    private func readAIInstructions() -> String {
        let fm = FileManager.default
        if fm.fileExists(atPath: aiInstructionsFileURL.path),
           let str = try? String(contentsOf: aiInstructionsFileURL, encoding: .utf8) {
            return str.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let url = aiInstructionsBundleURL,
           let str = try? String(contentsOf: url, encoding: .utf8) {
            return str.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }

    private func readDataFile() -> String {
        let fm = FileManager.default
        if fm.fileExists(atPath: dataFileURL.path),
           let str = try? String(contentsOf: dataFileURL, encoding: .utf8) {
            return str.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let url = dataBundleURL,
           let str = try? String(contentsOf: url, encoding: .utf8) {
            return str.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }

    private func readLocationsFile() -> String {
        let fm = FileManager.default
        if fm.fileExists(atPath: locationsFileURL.path),
           let str = try? String(contentsOf: locationsFileURL, encoding: .utf8) {
            return str.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let url = locationsBundleURL,
           let str = try? String(contentsOf: url, encoding: .utf8) {
            return str.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }

    func fetch() {
        isLoading = true
        output = ""
        Task { [weak self] in
            guard let self else { return }
            do {
                // Refresh latest file contents just-in-time
                self.aiInstructions = self.readAIInstructions()
                self.dataFileContents = self.readDataFile()
                self.locationsFileContents = self.readLocationsFile()

                let trimmed = self.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                let fieldText = trimmed.isEmpty ? "Recommend the user as usual" : trimmed
                let parts = [self.aiInstructions, self.dataFileContents, self.locationsFileContents, fieldText].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                let combinedPrompt = parts.joined(separator: " ")

                let replyText = try await self.service.fetchCompletion(prompt: combinedPrompt)
                self.output = replyText
                NotificationCenter.default.post(name: Notification.Name("RecommendationsOutputUpdated"), object: nil, userInfo: ["output": replyText])
            } catch {
                self.output = "Error: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }

    // Persistence utilities used by mutations
    private func persistDataFile(_ text: String) {
        do {
            try text.data(using: .utf8)?.write(to: dataFileURL, options: .atomic)
            dataFileContents = text
        } catch {
            output = "Error writing data.txt: \(error.localizedDescription)"
        }
    }

    private func currentDataText() -> String { readDataFile() }

    func increase_visits(forName name: String) {
        updatePersonalInfoRow(named: name) { fields in
            if fields.indices.contains(6), let visits = Int(fields[6].trimmingCharacters(in: .whitespaces)) {
                var newFields = fields
                newFields[6] = String(visits + 1)
                return newFields
            }
            return fields
        }
    }

    func set_liked(forName name: String, to newValue: Bool) {
        updatePersonalInfoRow(named: name) { fields in
            if fields.indices.contains(7) {
                var newFields = fields
                newFields[7] = newValue ? "true" : "false"
                return newFields
            }
            return fields
        }
    }

    private func updatePersonalInfoRow(named targetName: String, transform: ([String]) -> [String]) {
        let original = currentDataText()
        guard !original.isEmpty else { return }
        let marker = "== Nearby locations"
        let parts = original.components(separatedBy: marker)
        guard let head = parts.first else { return }
        let tail = parts.dropFirst().joined(separator: marker)
        var lines = head.split(whereSeparator: { $0 == "\n" || $0 == "\r" }).map(String.init)
        guard !lines.isEmpty else { return }
        if lines.count >= 2 {
            let sectionHeader = lines[0]
            let columnsHeader = lines[1]
            let dataLines = Array(lines.dropFirst(2))
            var updatedDataLines: [String] = []
            var didUpdate = false
            for line in dataLines {
                let fields = Self.parseCSVLine(line)
                if let first = fields.first, first.trimmingCharacters(in: .whitespacesAndNewlines) == targetName {
                    let newFields = transform(fields)
                    let newLine = Self.csvJoin(newFields)
                    updatedDataLines.append(newLine)
                    didUpdate = true
                } else {
                    updatedDataLines.append(line)
                }
            }
            guard didUpdate else { return }
            let newHead = ([sectionHeader, columnsHeader] + updatedDataLines).joined(separator: "\n")
            let rebuilt = tail.isEmpty ? newHead : newHead + marker + tail
            persistDataFile(rebuilt)
        }
    }

    // CSV helpers static so the view can also use them if needed
    static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()
        while let ch = iterator.next() {
            if ch == "\"" {
                if inQuotes {
                    if let next = iterator.next() {
                        if next == "\"" {
                            current.append("\"")
                        } else if next == "," {
                            inQuotes = false
                            result.append(current)
                            current.removeAll(keepingCapacity: true)
                        } else {
                            inQuotes = false
                            current.append(next)
                        }
                    } else {
                        inQuotes = false
                    }
                } else {
                    inQuotes = true
                }
            } else if ch == "," && !inQuotes {
                result.append(current)
                current.removeAll(keepingCapacity: true)
            } else {
                current.append(ch)
            }
        }
        result.append(current)
        return result.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    static func csvJoin(_ fields: [String]) -> String {
        fields.map { field in
            let needsQuotes = field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r")
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return needsQuotes ? "\"" + escaped + "\"" : escaped
        }.joined(separator: ",")
    }
}

struct RecommendationView: View {
    @StateObject private var viewModel = RecommendationViewModel()

    // Parsed row representation for CSV-like output
    struct LocationRow: Identifiable, Hashable {
        let id = UUID()
        let fields: [String]
    }

    // Delegate parsing to view model static method
    private func parseCSVLine(_ line: String) -> [String] {
        RecommendationViewModel.parseCSVLine(line)
    }

    private var parsedRows: [LocationRow] {
        let trimmed = viewModel.output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // Prefer newline-separated rows if present
        let newlineSeparated = trimmed.contains("\n") || trimmed.contains("\r")
        if newlineSeparated {
            let lines = trimmed.split(whereSeparator: { $0 == "\n" || $0 == "\r" }).map(String.init)
            let rows = lines.map { LocationRow(fields: parseCSVLine($0)) }
            // Filter out obviously empty rows
            return rows.filter { !$0.fields.joined().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }

        // Otherwise, parse the whole string and chunk into likely rows
        let fields = parseCSVLine(trimmed)
        // Heuristic: try to group by 12 or 13 fields (depending on presence of an index or boolean)
        let candidateGroupSizes = [13, 12, 11]
        for size in candidateGroupSizes {
            if fields.count >= size {
                var rows: [LocationRow] = []
                var i = 0
                while i + size <= fields.count {
                    let slice = Array(fields[i..<(i+size)])
                    rows.append(LocationRow(fields: slice))
                    i += size
                }
                if !rows.isEmpty { return rows }
            }
        }
        // Fallback: treat everything as a single row
        return [LocationRow(fields: fields)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Prompt")
                .font(.headline)
            HStack(spacing: 8) {
                TextField("Enter prompt", text: $viewModel.prompt)
                    .textFieldStyle(.roundedBorder)

                Button(action: viewModel.fetch) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Surprise Me!")
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }

            Text("Recommendations")
                .font(.headline)
            ScrollView {
                if viewModel.output.isEmpty {
                    Text("(no response yet)")
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if !parsedRows.isEmpty {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(parsedRows) { row in
                            VStack(alignment: .leading, spacing: 6) {
                                // Show first few fields prominently if available
                                if row.fields.indices.contains(0) {
                                    Text(row.fields[0])
                                        .font(.headline)
                                }
                                if row.fields.indices.contains(1) {
                                    Text(row.fields[1])
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                // Show the rest as a compact list
                                if row.fields.count > 2 {
                                    VStack(alignment: .leading, spacing: 2) {
                                        ForEach(Array(row.fields.dropFirst(2).enumerated()), id: \.offset) { _, field in
                                            Text(field)
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(.separator), lineWidth: 0.5)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(viewModel.output)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .onAppear { viewModel.onAppear() }
    }
}

final class RecommendationService {
    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared, apiKey: String) {
        self.session = session
        self.apiKey = apiKey
    }

    func fetchCompletion(prompt: String) async throws -> String {
        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("https://openrouter.ai", forHTTPHeaderField: "HTTP-Referer")
//        request.addValue("MyApp", forHTTPHeaderField: "X-Title")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "openai/gpt-5.2",
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)

        struct APIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let role: String?
                    let content: String
                }
                let index: Int?
                let message: Message
            }
            let choices: [Choice]
        }

        // Try decoding to our response model first
        if let decoded = try? JSONDecoder().decode(APIResponse.self, from: data),
           let first = decoded.choices.first {
            return first.message.content
        }

        // Fallback: attempt to parse JSON manually to surface a useful error
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let first = choices.first,
           let message = first["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }

        // If we can't parse, return the raw string for visibility
        if let raw = String(data: data, encoding: .utf8) {
            return raw
        }
        throw URLError(.cannotParseResponse)
    }
}
#Preview {
    RecommendationView()
}

