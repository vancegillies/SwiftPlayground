import Foundation
import Raylib

final class Shader {
    // MARK: - Types
    enum Error: Swift.Error {
        case notFound(String)
        case loadFailure(String)
        case uniformNotFound(String)
    }

    enum UniformType {
        case float
        case vec2

        var typeIndex: Int32 {
            switch self {
            case .float: return 0
            case .vec2: return 1
            }
        }
    }

    struct Uniform {
        let name: String
        let location: Int32
        let type: UniformType

        init(name: String, shader: Raylib.Shader, type: UniformType) {
            self.name = name
            self.location = GetShaderLocation(shader, name)
            self.type = type
        }
    }

    // MARK: - Properties
    private var shader: Raylib.Shader
    private var name: String
    private let path: String
    private var lastModified: Date
    private var uniforms: [String: Uniform]

    var current: Raylib.Shader { shader }

    // MARK: - Initialization
    init?(name: String, uniforms: [(String, UniformType)]) {
        do {
            guard let shaderPath = try Self.getPath(name: name, ext: "glsl") else {
                return nil
            }

            let loadedShader = try Self.load(name: name)
            self.shader = loadedShader
            self.name = name
            self.path = shaderPath
            self.lastModified = Self.getFileModificationDate(path: shaderPath) ?? Date()
            self.uniforms = Dictionary(
                uniqueKeysWithValues: uniforms.map { name, type in
                    (name, Uniform(name: name, shader: loadedShader, type: type))
                })
        } catch {
            print("Failed to initialize shader: \(error)")
            return nil
        }
    }

    func update() {
        checkAndReloadIfNeeded()
    }

    func updateUniform(_ name: String, update: (Uniform) throws -> Void) throws {
        guard let uniform = uniforms[name] else {
            throw Error.uniformNotFound(name)
        }
        try update(uniform)
    }

}

extension Shader {

    fileprivate static func load(name: String) throws -> Raylib.Shader {
        guard let path = try getPath(name: name, ext: "glsl") else {
            throw Error.notFound(name)
        }

        let shaderSource = try Shader.processIncludes(
            in: try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
        )

        let shader = LoadShaderFromMemory(nil, shaderSource)
        guard shader.id != 0 else {
            throw Error.loadFailure(name)
        }

        return shader
    }

    fileprivate static func getPath(name: String, ext: String) throws -> String? {
        return Bundle.module.url(
            forResource: name,
            withExtension: ext
        )?.path
    }

    fileprivate static func getFileModificationDate(path: String) -> Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        return attributes?[.modificationDate] as? Date
    }

    private static func processIncludes(in source: String) throws -> String {
        var processedSource = source

        // Regular expression to find #include "filename.glsl"
        let includePattern = try NSRegularExpression(pattern: #"#include\s*\"([^\"]+)\""#)

        while let match = includePattern.firstMatch(
            in: processedSource, range: NSRange(processedSource.startIndex..., in: processedSource))
        {
            guard let includeRange = Range(match.range, in: processedSource),
                let fileNameRange = Range(match.range(at: 1), in: processedSource)
            else {
                continue
            }

            let fileName = String(processedSource[fileNameRange])

            // Load included file
            guard
                let includeURL = try Shader.getPath(
                    name: fileName.replacingOccurrences(of: ".glsl", with: ""), ext: "glsl")
            else {
                throw Error.notFound(fileName)
            }

            let includeContent = try String(
                contentsOf: URL(fileURLWithPath: includeURL), encoding: .utf8)

            // Replace include directive with file content
            processedSource.replaceSubrange(includeRange, with: includeContent)
        }

        return processedSource
    }

    func checkAndReloadIfNeeded() {
        guard let modDate = Self.getFileModificationDate(path: path),
            modDate > lastModified
        else {
            return
        }

        reloadShader()
    }

    func reloadShader() {
        do {
            print("Reloading shader...")
            let newShader = try Self.load(name: self.name)
            let uniformDefinitions = uniforms.map { ($0.key, $0.value.type) }
            UnloadShader(shader)
            shader = newShader
            lastModified = Date()
            uniforms = Dictionary(
                uniqueKeysWithValues: uniformDefinitions.map { name, type in
                    (name, Uniform(name: name, shader: shader, type: type))
                })
        } catch {
            print("Failed to reload shader: \(error)")
        }
    }
}
