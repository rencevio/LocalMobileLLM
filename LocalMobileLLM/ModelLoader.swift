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
        case smolLM135Mx4b
        case smolLM135Mx8b
        case smolLM135Mxfp16
        case smolLM360Mx4b
        case smolLM360Mx8b
        case smolLM360Mxfp16
        case smolLM1p7Bx4b
        case smolLM1p7Bx8b
        case smolLM1p7Bxfp16

        var configuration: ModelConfiguration {
            switch self {
            case .smolLM135Mx4b:
                    .init(id: "mlx-community/SmolLM-135M-Instruct-4bit")
            case .smolLM135Mx8b:
                    .init(id: "mlx-community/SmolLM-135M-Instruct-8bit")
            case .smolLM135Mxfp16:
                    .init(id: "mlx-community/SmolLM-135M-Instruct-fp16")
            case .smolLM360Mx4b:
                    .init(id: "mlx-community/SmolLM-360M-Instruct-4bit")
            case .smolLM360Mx8b:
                    .init(id: "mlx-community/SmolLM-360M-Instruct-8bit")
            case .smolLM360Mxfp16:
                    .init(id: "mlx-community/SmolLM-360M-Instruct-fp16")
            case .smolLM1p7Bx4b:
                    .init(id: "mlx-community/SmolLM-1.7B-Instruct-4bit")
            case .smolLM1p7Bx8b:
                    .init(id: "mlx-community/SmolLM-1.7B-Instruct-8bit")
            case .smolLM1p7Bxfp16:
                    .init(id: "mlx-community/SmolLM-1.7B-Instruct-fp16")
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
