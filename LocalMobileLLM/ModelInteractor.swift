//
//  ModelInteractor.swift
//  LocalMobileLLM
//
//  Created by Max on 05/11/2024.
//

import SwiftUI
import MLXLLM
import MLXRandom

@Observable
class ModelInteractor {
    var isGenerating: Bool = false
    var output: String = ""

    func generate(
        prompt: String,
        container: ModelContainer,
        parameters: GenerateParameters,
        configuration: ModelConfiguration,
        maxTokens: Int = 420
    ) async {
        guard !isGenerating else { return }

        isGenerating = true

        do {
            let messages = [["role": "user", "content": prompt]]
            let promptTokens = try await container.perform { _, tokenizer in
                try tokenizer.applyChatTemplate(messages: messages)
            }

            MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))

            let result = await container.perform { model, tokenizer in
                MLXLLM.generate(
                    promptTokens: promptTokens,
                    parameters: parameters,
                    model: model,
                    tokenizer: tokenizer,
                    extraEOSTokens: configuration.extraEOSTokens
                ) { tokens in
                    if tokens.count % 4 == 0 {
                        let text = tokenizer.decode(tokens: tokens)
                        Task { @MainActor in
                            self.output = text
                        }
                    }

                    if tokens.count >= maxTokens {
                        return .stop
                    } else {
                        return .more
                    }
                }
            }

            if result.output != self.output {
                self.output = result.output
            }
//            self.stat = " Tokens/second: \(String(format: "%.3f", result.tokensPerSecond))"
        } catch {
            output = "Failed: \(error)"
        }

        isGenerating = false
    }
}

