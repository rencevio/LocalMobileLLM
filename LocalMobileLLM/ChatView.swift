import SwiftUI
import MLXLLM

struct ChatView: View {
    @State private var inputText: String = ""
    @State private var messages: [String] = []
    @State private var lastOutput: String = ""
    @State private var selectedModel: ModelLoader.Model = .smolLM135Mx4b

    @State private var modelLoader = ModelLoader()
    @State private var modelInteractor = ModelInteractor()

    private var isInterfaceDisabled: Bool {
        !isModelReady() || modelInteractor.isGenerating
    }

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

            if let modelState = modelLoader.modelStates[selectedModel] {
                switch modelState {
                case .notLoaded:
                    Button("Download Model") {
                        Task {
                            do {
                                try await modelLoader.load(model: selectedModel)
                            } catch {
                                print(error)
                            }
                        }
                    }
                    .padding()

                case .loading(let percent):
                    ProgressView(value: percent, total: 100) {
                        Text("Downloading... \(Int(percent))%")
                    }
                    .padding()

                case .ready:
                    EmptyView()
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages + [modelInteractor.output], id: \.self) { message in
                        if !message.isEmpty {
                            Text(message)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }

            if !isInterfaceDisabled {
                HStack {
                    TextField("Type a message...", text: $inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: sendMessage) {
                        Text("Send")
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
        }
    }

    func isModelReady() -> Bool {
        if let modelState = modelLoader.modelStates[selectedModel],
           case .ready = modelState {
            return true
        }
        return false
    }

    func sendMessage() {
        guard !inputText.isEmpty else { return }

        if !modelInteractor.output.isEmpty {
            messages.append(modelInteractor.output)
        }

        messages.append("You: \(inputText)")

        guard let modelState = modelLoader.modelStates[selectedModel],
              case let .ready(modelContainer) = modelState else {
            messages.append("\(selectedModel.rawValue): [Model not ready]")
            return
        }

        let input = inputText
        inputText = ""

        Task {
            await generateResponse(
                input: input,
                container: modelContainer,
                temperature: 0.6,
                configuration: selectedModel.configuration
            )
        }
    }

    func generateResponse(
        input: String,
        container: ModelContainer,
        temperature: Float,
        configuration: ModelConfiguration
    ) async {
        await modelInteractor
            .generate(
                prompt: input,
                container: container,
                parameters: .init(temperature: temperature),
                configuration: configuration
            )
    }
}
