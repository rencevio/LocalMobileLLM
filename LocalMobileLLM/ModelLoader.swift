//
//  ModelLoader.swift
//  LocalMobileLLM
//
//  Created by Max on 05/11/2024.
//

import SwiftUI
import MLXLLM
import MLX

@Observable
class ModelLoader {
    enum Model: String, CaseIterable {
        case smolLM125M
        case mobileLLM125M
        case mobileLLM350M
        case mobileLLM600M
        case mobileLLM1B

        var configuration: ModelConfiguration {
            switch self {
            case .smolLM125M:
                    .smolLM_135M_4bit
            case .mobileLLM125M:
                    .init(id: "facebook/MobileLLM-125M")
            case .mobileLLM350M:
                    .init(id: "facebook/MobileLLM-350M")
            case .mobileLLM600M:
                    .init(id: "facebook/MobileLLM-600M")
            case .mobileLLM1B:
                    .init(id: "facebook/MobileLLM-1B")
            }
        }
    }

    enum ModelState {
        case notLoaded
        case loading(percent: Double)
        case ready(ModelContainer)
    }

    var modelStates: [Model: ModelState] = {
        .init(uniqueKeysWithValues: Model.allCases.map { ($0, ModelState.notLoaded) })
    }()

    func load(model: Model) async throws {
        guard let modelState = modelStates[model] else {
            fatalError("ooopsie")
        }

        switch modelState {
        case .notLoaded:
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)

            let modelContainer = try await MLXLLM.loadModelContainer(configuration: model.configuration) { progress in
                Task { @MainActor in
                    self.modelStates[model] = .loading(percent: progress.fractionCompleted * 100)
                }
            }

            //            let numParams = await modelContainer.perform {
            //                [] model, _ in
            //                return model.numParameters()
            //            }
            //
            //            self.modelInfo =
            //            "Loaded \(modelConfiguration.id).  Weights: \(numParams / (1024*1024))M"
            modelStates[model] = .ready(modelContainer)

        case .loading, .ready:
            break
        }
    }
}
