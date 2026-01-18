import SwiftUI
import Foundation

// NOTE: Do not hardcode secrets in source for production apps.
struct RecommendationView: View {
    @State private var prompt: String = ""
    @State private var output: String = ""
    @State private var isLoading: Bool = false

    @State private var aiInstructions: String = ""
    @State private var dataFileContents: String = ""
    @State private var locationsFileContents: String = ""

    // Parsed row representation for CSV-like output
    struct LocationRow: Identifiable, Hashable {
        let id = UUID()
        let fields: [String]
    }

    // Parses a single CSV-like line into fields, handling quoted commas
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()
        while let ch = iterator.next() {
            if ch == "\"" { // toggle quote state or escape quotes
                if inQuotes {
                    // Lookahead: if next is a quote, it's an escaped quote
                    if let next = iterator.next() {
                        if next == "\"" { // escaped quote
                            current.append("\"")
                        } else if next == "," { // end of quoted field
                            inQuotes = false
                            result.append(current)
                            current.removeAll(keepingCapacity: true)
                        } else {
                            // End quote, continue reading the next char
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

    // Attempt to split the output into multiple rows. We support either newline-separated rows
    // or a single line with repeating groups of fields. We treat 12-13 fields per row as typical.
    private var parsedRows: [LocationRow] {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    // Bundle resources (read-only) for initial seed
    private var aiInstructionsBundleURL: URL? { Bundle.main.url(forResource: "AIinstructions", withExtension: "txt") }
    private var dataBundleURL: URL? { Bundle.main.url(forResource: "data", withExtension: "txt") }
    private var locationsBundleURL: URL? { Bundle.main.url(forResource: "locations", withExtension: "txt") }

    // Writable copies in Documents
    private var aiInstructionsFileURL: URL { documentsURL.appendingPathComponent("AIinstructions.txt") }
    private var dataFileURL: URL { documentsURL.appendingPathComponent("data.txt") }
    private var locationsFileURL: URL { documentsURL.appendingPathComponent("locations.txt") }

    // Note: No seeding. We only read from Documents if present; otherwise we fall back to bundled read-only files.
    private func ensureSeedFiles() {
        // Intentionally left blank: no file writes. We only read existing files.
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

    /// Reads/writes data.txt so it can be called later after API instructions.
    private func writeDataFile(_ text: String) {
        // Writes are disabled per current requirements. Keeping function for future use.
        // do {
        //     try text.data(using: .utf8)?.write(to: dataFileURL, options: .atomic)
        //     dataFileContents = text
        // } catch {
        //     output = "Error writing data.txt: \(error.localizedDescription)"
        // }
    }

    private let service = RecommendationService(apiKey: "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")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Prompt")
                .font(.headline)
            HStack(spacing: 8) {
                TextField("Enter prompt", text: $prompt)
                    .textFieldStyle(.roundedBorder)

                Button(action: fetch) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Text("Recommendations")
                .font(.headline)
            ScrollView {
                if output.isEmpty {
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
                    Text(output)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .onAppear {
            ensureSeedFiles()
            aiInstructions = readAIInstructions()
            dataFileContents = readDataFile()
            locationsFileContents = readLocationsFile()
        }
    }

    private func fetch() {
        isLoading = true
        output = ""
        Task {
            do {
                // Refresh latest file contents just-in-time
                aiInstructions = readAIInstructions()
                dataFileContents = readDataFile()
                locationsFileContents = readLocationsFile()

                let fieldText = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = [aiInstructions, dataFileContents, locationsFileContents, fieldText].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                let combinedPrompt = parts.joined(separator: " ")

                let replyText = try await service.fetchCompletion(prompt: combinedPrompt)
                output = replyText
            } catch {
                output = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
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

