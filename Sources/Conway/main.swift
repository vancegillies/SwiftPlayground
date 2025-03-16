import Foundation
import Raylib

struct Board {
    var cells: [[Bool]]
    let cellSize: Int32 = 20
    let cellPadding: Int32 = 1

    private var simulationRunning = false
    private var frameCount = 0
    private let framesPerUpdate = 5
    private var shouldUpdate = true

    init(size: Int) {
        self.cells = Array(repeating: Array(repeating: false, count: size), count: size)

    }

    mutating func reset() {
        cells = Array(repeating: Array(repeating: false, count: cells[0].count), count: cells.count)
    }

    mutating func toggleSimulation() {
        simulationRunning = !simulationRunning
    }

    mutating func tick() {
        if shouldUpdate && simulationRunning {
            update()
            shouldUpdate = false
        }

        frameCount += 1
        if frameCount >= framesPerUpdate {
            frameCount = 0
            shouldUpdate = true
        }
    }

    var isRunning: Bool {
        simulationRunning
    }

    func worldToCell(_ position: Vector2) -> (x: Int, y: Int)? {
        // Simply divide by cellSize to get the cell coordinates
        let x = Int(floor(position.x / Float(cellSize)))
        let y = Int(floor(position.y / Float(cellSize)))

        // Check if these coordinates are valid
        if isValidCell(x: x, y: y) {
            return (x, y)
        }
        return nil
    }

    func isValidCell(x: Int, y: Int) -> Bool {
        return x >= 0 && x < cells[0].count && y >= 0 && y < cells.count
    }

    mutating func handleClickedCell(_ position: Vector2, _ state: Bool) {
        if let (x, y) = worldToCell(position) {
            cells[y][x] = state
        }
    }

    func countNeighbors(x: Int, y: Int) -> Int {
        var count = 0

        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 {
                    continue
                }

                let newX = x + dx
                let newY = y + dy

                if isValidCell(x: newX, y: newY) && cells[newY][newX] {
                    count += 1
                }
            }
        }

        return count
    }

    mutating func update() {
        var newCells = cells

        for y in 0..<cells.count {
            for x in 0..<cells[y].count {
                let neighbors = countNeighbors(x: x, y: y)

                if cells[y][x] {
                    newCells[y][x] = neighbors == 2 || neighbors == 3
                } else {
                    newCells[y][x] = neighbors == 3
                }
            }
        }

        cells = newCells
    }

    func render() {
        for y in 0..<cells.count {
            for x in 0..<cells[y].count {
                let xPos = Int32(x) * cellSize
                let yPos = Int32(y) * cellSize

                // Draw cell content
                if cells[y][x] {
                    DrawRectangle(
                        xPos + cellPadding,
                        yPos + cellPadding,
                        cellSize - cellPadding * 2,
                        cellSize - cellPadding * 2,
                        Color(r: 255, g: 255, b: 255, a: 255)
                    )
                } else {
                    // Draw cell background
                    DrawRectangle(
                        xPos + cellPadding,
                        yPos + cellPadding,
                        cellSize - cellPadding * 2,
                        cellSize - cellPadding * 2,
                        Color(r: 40, g: 40, b: 40, a: 255)
                    )
                }
            }
        }
    }
}

class CameraController {
    var camera: Camera2D
    var dragStart: Vector2?
    var cameraStart: Vector2?
    let moveSpeed: Float = 10.0

    init() {
        camera = Camera2D()
        camera.zoom = 1.0
    }

    func update() {
        // WASD Movement
        if IsKeyDown(Int32(KEY_W.rawValue)) { camera.target.y -= moveSpeed / camera.zoom }
        if IsKeyDown(Int32(KEY_S.rawValue)) { camera.target.y += moveSpeed / camera.zoom }
        if IsKeyDown(Int32(KEY_A.rawValue)) { camera.target.x -= moveSpeed / camera.zoom }
        if IsKeyDown(Int32(KEY_D.rawValue)) { camera.target.x += moveSpeed / camera.zoom }

        // Right click drag
        if IsMouseButtonPressed(2) {  // Right button
            dragStart = GetMousePosition()
            cameraStart = camera.target
        }

        if IsMouseButtonDown(2) {
            if let start = dragStart, let camStart = cameraStart {
                let current = GetMousePosition()
                let delta = Vector2(
                    x: (start.x - current.x) / camera.zoom,
                    y: (start.y - current.y) / camera.zoom
                )
                camera.target = Vector2(
                    x: camStart.x + delta.x,
                    y: camStart.y + delta.y
                )
            }
        }

        // Mouse wheel zoom
        let wheel = GetMouseWheelMove()
        if wheel != 0 {
            // Get the world point that we're zooming in/out on
            let mousePos = GetMousePosition()
            let beforeZoom = GetScreenToWorld2D(mousePos, camera)

            // Zoom
            camera.zoom += wheel * 0.1
            camera.zoom = max(0.5, camera.zoom)  // Prevent negative or zero zoom

            // Get the world point after zoom
            let afterZoom = GetScreenToWorld2D(mousePos, camera)

            // Adjust target to zoom into the mouse position
            camera.target.x += beforeZoom.x - afterZoom.x
            camera.target.y += beforeZoom.y - afterZoom.y
        }
    }
}

// ========== CONFIG ===========
let SCREEN_WIDTH = 1920
let SCREEN_HEIGHT = 1080
let BOARD_SIZE = 50

InitWindow(Int32(SCREEN_WIDTH), Int32(SCREEN_HEIGHT), "Conway")
SetTargetFPS(60)

var board = Board(size: BOARD_SIZE)
var controller = CameraController()

// Center camera on board
let boardPixelWidth = Float(board.cellSize * Int32(board.cells[0].count))
let boardPixelHeight = Float(board.cellSize * Int32(board.cells.count))
let screenWidth = Float(SCREEN_WIDTH)
let screenHeight = Float(SCREEN_HEIGHT)
let zoomX = screenWidth / boardPixelWidth
let zoomY = screenHeight / boardPixelHeight
controller.camera.zoom = min(zoomX, zoomY) * 0.9
controller.camera.target = Vector2(
    x: -((screenWidth / controller.camera.zoom) - boardPixelWidth) / 2,
    y: -((screenHeight / controller.camera.zoom) - boardPixelHeight) / 2
)
while !WindowShouldClose() {
    controller.update()

    if IsMouseButtonDown(0) || IsMouseButtonDown(1) {
        let worldPos = GetScreenToWorld2D(GetMousePosition(), controller.camera)
        board.handleClickedCell(worldPos, IsMouseButtonDown(0))
    }

    if IsKeyPressed(32) {  // Space
        board.toggleSimulation()
    }

    if IsKeyPressed(82) {  // R
        board.reset()
    }

    board.tick()

    BeginDrawing()
    ClearBackground(Color(r: 50, g: 50, b: 50, a: 255))
    BeginMode2D(controller.camera)

    board.render()

    EndMode2D()

    DrawFPS(10, 10)

    DrawText("State: ", 10, 40, 20, Color(r: 255, g: 255, b: 255, a: 255))
    DrawText(
        board.isRunning ? "Running" : "Paused",
        10 + 100,
        40,
        20,
        Color(r: 255, g: 255, b: 255, a: 255)
    )

    EndDrawing()
}
CloseWindow()
