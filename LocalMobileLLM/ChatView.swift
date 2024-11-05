import SwiftUI
import MLXLLM

struct ChatView: View {
    @State private var inputText: String = ""
    @State private var messages: [String] = []
    @State private var selectedModel: ModelLoader.Model = .smolLM125M

    @State private var modelLoader = ModelLoader()

    var body: some View {
        VStack {
            // Model Selector
            Picker("Select Model", selection: $selectedModel) {
                ForEach(ModelLoader.Model.allCases, id: \.self) { model in
                    Text(model.rawValue).tag(model)
                }
            }
            .padding()
            .pickerStyle(MenuPickerStyle())

            // Download Button and Progress Indicator
            if let modelState = modelLoader.modelStates[selectedModel] {
                switch modelState {
                case .notLoaded:
                    Button("Download Model") {
                        Task {
                            try await modelLoader.load(model: selectedModel)
                        }
                    }
                    .padding()

                case .loading(let percent):
                    ProgressView(value: percent, total: 100) {
                        Text("Downloading... \(Int(percent))%")
                    }
                    .padding()

                case .ready:
                    Text("Model Loaded")
                        .padding()
                }
            }

            // Chat Display Area
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages, id: \.self) { message in
                        Text(message)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }

            // Input Field and Send Button
            HStack {
                TextField("Type a message...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(!isModelReady())

                Button(action: sendMessage) {
                    Text("Send")
                        .padding(.horizontal)
                }
                .disabled(!isModelReady())
            }
            .padding()
        }
    }

    // Check if the selected model is ready
    func isModelReady() -> Bool {
        if let modelState = modelLoader.modelStates[selectedModel],
           case .ready = modelState {
            return true
        }
        return false
    }

    // Function to send message
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        messages.append("You: \(inputText)")

        guard let modelState = modelLoader.modelStates[selectedModel],
              case let .ready(modelContainer) = modelState else {
            messages.append("\(selectedModel.rawValue): [Model not ready]")
            return
        }

        // Generate response using the loaded model
        Task {
            let response = await generateResponse(input: inputText, modelContainer: modelContainer)
            await MainActor.run {
                messages.append("\(selectedModel.rawValue): \(response)")
                inputText = ""
            }
        }
    }

    func generateResponse(input: String, modelContainer: ModelContainer) async -> String {
        return "Implement this bro"
    }
}
