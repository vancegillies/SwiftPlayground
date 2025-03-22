import Foundation
import Raylib

func listShaders() -> [String] {
    Bundle.module.paths(forResourcesOfType: "glsl", inDirectory: "Resources").map { path in
        return String(path.split(separator: "/").last!.split(separator: ".").first!)
    }
}

func main() {

    guard CommandLine.arguments.count > 1 else {
        print(
            "\nNo shader name provided\nPossible options: \(listShaders().joined(separator: ", "))\nRun with swift run Shader <shader_name>\n"
        )
        return
    }
    let shaderName = CommandLine.arguments[1]
    var time: Float = 0.0
    var window = Vector2(x: 1000.0, y: 1000.0)
    var shaderResolution: [Float] = [window.x, window.y]

    InitWindow(Int32(window.x), Int32(window.y), "Fullscreen Shader")
    SetWindowState(0x0000_0004)
    defer { CloseWindow() }

    guard
        let shader = Shader(
            name: shaderName,
            uniforms: [
                ("time", .float),
                ("resolution", .vec2),
            ])
    else {
        fatalError("Failed to load shader")
    }

    SetTargetFPS(60)

    while !WindowShouldClose() {
        time += GetFrameTime()
        window.x = Float(GetScreenWidth())
        window.y = Float(GetScreenHeight())
        shaderResolution = [window.x, window.y]
        do {
            try shader.updateUniform("time") { t in
                SetShaderValue(shader.current, t.location, &time, t.type.typeIndex)
            }
            try shader.updateUniform("resolution") { r in
                SetShaderValue(shader.current, r.location, &shaderResolution, r.type.typeIndex)
            }
        } catch {
            print("Error updating shader: \(error)")
        }
        shader.update()

        BeginDrawing()
        ClearBackground(.init(r: 0, g: 0, b: 0, a: 255))

        // Draw fullscreen shader
        BeginShaderMode(shader.current)
        DrawRectangle(0, 0, Int32(window.x), Int32(window.y), .init(r: 255, g: 255, b: 255, a: 255))
        EndShaderMode()

        EndDrawing()
    }

    UnloadShader(shader.current)
}

main()
