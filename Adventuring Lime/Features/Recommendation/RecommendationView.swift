//import Foundation
//
//let apiKey = "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"
//let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
//
//var request = URLRequest(url: url)
//request.httpMethod = "POST"
//request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//request.addValue("<YOUR_SITE_URL>", forHTTPHeaderField: "HTTP-Referer")
//request.addValue("<YOUR_SITE_NAME>", forHTTPHeaderField: "X-Title")
//request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//var prompt = "banana"  // TODO
//
//let body: [String: Any] = [
//    "model": "openai/gpt-5.2",
//    "messages": [
//        ["role": "user", "content": "What is the meaning of life?"]
//    ]
//]
//
//request.httpBody = try JSONSerialization.data(withJSONObject: body)
//
//URLSession.shared.dataTask(with: request) { data, response, error in
//    if let data = data {
//        let json = try? JSONSerialization.jsonObject(with: data)
//        print(json ?? "No response")
//    }
//}.resume()


