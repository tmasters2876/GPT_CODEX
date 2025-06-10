import Foundation
import FoundationNetworking

// Reads OpenAI API key from environment variable
let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
if apiKey.isEmpty {
    fputs("Error: OPENAI_API_KEY environment variable not set\n", stderr)
    exit(1)
}

print("Enter your question:", terminator: " ")
if let question = readLine(), !question.isEmpty {
    let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let json: [String: Any] = [
        "model": "gpt-3.5-turbo",
        "messages": [["role": "user", "content": question]],
        "max_tokens": 150
    ]

    guard let body = try? JSONSerialization.data(withJSONObject: json, options: []) else {
        print("Failed to encode request body")
        exit(1)
    }
    request.httpBody = body

    let semaphore = DispatchSemaphore(value: 0)

    URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        if let error = error {
            print("Request error: \(error)")
            return
        }
        guard let data = data else {
            print("No data received")
            return
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            print("\nAnswer: \(content.trimmingCharacters(in: .whitespacesAndNewlines))")
        } else if let text = String(data: data, encoding: .utf8) {
            print("Unexpected response: \(text)")
        } else {
            print("Failed to decode response")
        }
    }.resume()

    semaphore.wait()
} else {
    print("No question provided")
}
