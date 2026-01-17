import SwiftUI
import Foundation

// NOTE: Do not hardcode secrets in source for production apps.
struct RecommendationView: View {
    @State private var prompt: String = "banana"
    @State private var output: String = ""
    @State private var isLoading: Bool = false

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var promptFileURL: URL { documentsURL.appendingPathComponent("prompt.txt") }
    private var outputFileURL: URL { documentsURL.appendingPathComponent("output.txt") }

    private func loadPromptFromFile() {
        do {
            let data = try Data(contentsOf: promptFileURL)
            if let text = String(data: data, encoding: .utf8) {
                prompt = text
            } else {
                output = "Error: prompt.txt is not valid UTF-8"
            }
        } catch {
            output = "Error reading prompt.txt: \(error.localizedDescription)"
        }
    }

    private func writeOutputToFile(_ text: String) {
        do {
            try text.data(using: .utf8)?.write(to: outputFileURL, options: .atomic)
        } catch {
            output = "Error writing output.txt: \(error.localizedDescription)"
        }
    }

    private let service = RecommendationService(apiKey: "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")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Prompt")
                .font(.headline)
            TextField("Enter prompt", text: $prompt)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                Button("Load prompt.txt") {
                    loadPromptFromFile()
                }
                .buttonStyle(.bordered)

                Button(action: fetch) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Send and write output.txt")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Text("Response")
                .font(.headline)
            ScrollView {
                Text(output.isEmpty ? "(no response yet)" : output)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .onAppear {
            // Try to load prompt.txt automatically if it exists
            if FileManager.default.fileExists(atPath: promptFileURL.path) {
                loadPromptFromFile()
            }
        }
    }

    private func fetch() {
        isLoading = true
        output = ""
        Task {
            do {
                let json = try await service.fetchCompletion(prompt: prompt)
                output = String(describing: json)
                writeOutputToFile(output)
            } catch {
                output = "Error: \(error)"
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

    func fetchCompletion(prompt: String) async throws -> Any {
        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("<YOUR_SITE_URL>", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("<YOUR_SITE_NAME>", forHTTPHeaderField: "X-Title")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "openai/gpt-5.2",
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data)
        return json
    }
}
#Preview {
    RecommendationView()
}

