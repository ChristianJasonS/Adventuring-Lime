import SwiftUI
import Foundation
import Combine
import MapKit

// ✅ FIX 1: Define the Notification Name globally here
extension Notification.Name {
    static let recommendationsOutputUpdated = Notification.Name("RecommendationsOutputUpdated")
}

@MainActor
final class RecommendationViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var output: String = ""
    @Published var isLoading: Bool = false

    @Published var aiInstructions: String = ""
    @Published var dataFileContents: String = ""
    @Published var locationsFileContents: String = ""

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
    }

    private func readAIInstructions() -> String {
        if let str = try? String(contentsOf: aiInstructionsFileURL, encoding: .utf8) { return str }
        if let url = aiInstructionsBundleURL, let str = try? String(contentsOf: url, encoding: .utf8) { return str }
        return ""
    }

    private func readDataFile() -> String {
        if let str = try? String(contentsOf: dataFileURL, encoding: .utf8) { return str }
        if let url = dataBundleURL, let str = try? String(contentsOf: url, encoding: .utf8) { return str }
        return ""
    }

    private func readLocationsFile() -> String {
        if let str = try? String(contentsOf: locationsFileURL, encoding: .utf8) { return str }
        if let url = locationsBundleURL, let str = try? String(contentsOf: url, encoding: .utf8) { return str }
        return ""
    }

    func fetch() {
        isLoading = true
        output = ""
        
        Task {
            do {
                // Refresh context
                self.aiInstructions = self.readAIInstructions()
                self.dataFileContents = self.readDataFile()
                self.locationsFileContents = self.readLocationsFile()

                let trimmed = self.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                let fieldText = trimmed.isEmpty ? "Recommend the user as usual" : trimmed
                
                // Construct Prompt
                let parts = [self.aiInstructions, self.dataFileContents, self.locationsFileContents, fieldText]
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                let combinedPrompt = parts.joined(separator: "\n\n")

                // Call API
                let replyText = try await self.service.fetchCompletion(prompt: combinedPrompt)
                
                // Update UI
                self.output = replyText
                
                // Broadcast to Map
                NotificationCenter.default.post(name: .recommendationsOutputUpdated, object: nil, userInfo: ["output": replyText])
            } catch {
                self.output = "Error: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
    
    static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for ch in line {
            if ch == "\"" { inQuotes.toggle() }
            else if ch == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(ch)
            }
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
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
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("https://adventurelime.app", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("AdventureLime", forHTTPHeaderField: "X-Title")

        let body: [String: Any] = [
            // ✅ FIX 2: Use a VALID model name. 'gpt-5.2' caused the -1011 error.
            "model": "openai/gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        
        // Handle non-200 responses
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorObj = errorJson["error"] as? [String: Any],
               let message = errorObj["message"] as? String {
                throw NSError(domain: "API Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw URLError(.badServerResponse)
        }

        struct APIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        if let decoded = try? JSONDecoder().decode(APIResponse.self, from: data),
           let first = decoded.choices.first {
            return first.message.content
        }
        
        // Fallback for raw text
        if let raw = String(data: data, encoding: .utf8) {
            return raw
        }
        
        throw URLError(.cannotParseResponse)
    }
}

struct RecommendationView: View {
    @StateObject private var viewModel = RecommendationViewModel()

    struct LocationRow: Identifiable {
        let id = UUID()
        let fields: [String]
    }
    
    var parsedRows: [LocationRow] {
        let trimmed = viewModel.output.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return [] }
        let lines = trimmed.components(separatedBy: .newlines)
        return lines.map { LocationRow(fields: RecommendationViewModel.parseCSVLine($0)) }
            .filter { $0.fields.count > 1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Concierge")
                .font(.largeTitle.bold())
                .foregroundColor(.orange)
            
            HStack(spacing: 8) {
                TextField("What are you looking for?", text: $viewModel.prompt)
                    .textFieldStyle(.roundedBorder)

                Button(action: viewModel.fetch) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                }
                .disabled(viewModel.isLoading)
            }

            Text("Recommendations")
                .font(.headline)
            
            ScrollView {
                if viewModel.output.isEmpty {
                    ContentUnavailableView("No recommendations yet", systemImage: "magnifyingglass")
                } else if !parsedRows.isEmpty {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(parsedRows) { row in
                            VStack(alignment: .leading) {
                                Text(row.fields[0]).font(.headline)
                                if row.fields.count > 1 {
                                    Text(row.fields[1]).font(.subheadline).foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                } else {
                    Text(viewModel.output)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .onAppear { viewModel.onAppear() }
    }
}
