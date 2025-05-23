import SwiftUI // For CGFloat and Identifiable, though Foundation might be enough for CGFloat

// Define the structures
struct Node: Identifiable {
    let id = UUID()
    var x: CGFloat // Normalized coordinate
    var y: CGFloat // Normalized coordinate
}

struct Edge { // Not identifiable, as it's part of a Level
    let from: Int // Index in the Level's nodes array
    let to: Int   // Index in the Level's nodes array
}

struct Level: Identifiable {
    let id = UUID()
    var name: String
    var nodes: [Node]
    var edges: [Edge]

    // Static data source for levels
    static let allLevels: [Level] = [
        // Level 1: Triangle
        // JS nodes:
        // { x: centerX, y: centerY - maxSize * 0.8 }
        // { x: centerX - maxSize * 0.8, y: centerY + maxSize * 0.6 }
        // { x: centerX + maxSize * 0.8, y: centerY + maxSize * 0.6 }
        // Normalized: (dx * 0.5, dy * 0.5)
        Level(
            name: "Triangle",
            nodes: [
                Node(x: 0.0 * 0.5, y: -0.8 * 0.5),           // Node(x: 0.0,  y: -0.4)
                Node(x: -0.8 * 0.5, y: 0.6 * 0.5),          // Node(x: -0.4, y: 0.3)
                Node(x: 0.8 * 0.5, y: 0.6 * 0.5)           // Node(x: 0.4,  y: 0.3)
            ],
            edges: [
                Edge(from: 0, to: 1),
                Edge(from: 1, to: 2),
                Edge(from: 2, to: 0)
            ]
        ),

        // Level 2: Square
        // JS nodes:
        // { x: centerX - maxSize * 0.7, y: centerY - maxSize * 0.7 }
        // { x: centerX + maxSize * 0.7, y: centerY - maxSize * 0.7 }
        // { x: centerX + maxSize * 0.7, y: centerY + maxSize * 0.7 }
        // { x: centerX - maxSize * 0.7, y: centerY + maxSize * 0.7 }
        Level(
            name: "Square",
            nodes: [
                Node(x: -0.7 * 0.5, y: -0.7 * 0.5),         // Node(x: -0.35, y: -0.35)
                Node(x: 0.7 * 0.5, y: -0.7 * 0.5),          // Node(x: 0.35,  y: -0.35)
                Node(x: 0.7 * 0.5, y: 0.7 * 0.5),           // Node(x: 0.35,  y: 0.35)
                Node(x: -0.7 * 0.5, y: 0.7 * 0.5)          // Node(x: -0.35, y: 0.35)
            ],
            edges: [
                Edge(from: 0, to: 1),
                Edge(from: 1, to: 2),
                Edge(from: 2, to: 3),
                Edge(from: 3, to: 0)
            ]
        ),

        // Level 3: Pentagon
        // JS nodes:
        // { x: centerX, y: centerY - maxSize * 0.9 }
        // { x: centerX + maxSize * 0.85, y: centerY - maxSize * 0.3 }
        // { x: centerX + maxSize * 0.5, y: centerY + maxSize * 0.8 }
        // { x: centerX - maxSize * 0.5, y: centerY + maxSize * 0.8 }
        // { x: centerX - maxSize * 0.85, y: centerY - maxSize * 0.3 }
        Level(
            name: "Pentagon",
            nodes: [
                Node(x: 0.0 * 0.5, y: -0.9 * 0.5),          // Node(x: 0.0,   y: -0.45)
                Node(x: 0.85 * 0.5, y: -0.3 * 0.5),         // Node(x: 0.425, y: -0.15)
                Node(x: 0.5 * 0.5, y: 0.8 * 0.5),           // Node(x: 0.25,  y: 0.4)
                Node(x: -0.5 * 0.5, y: 0.8 * 0.5),          // Node(x: -0.25, y: 0.4)
                Node(x: -0.85 * 0.5, y: -0.3 * 0.5)         // Node(x: -0.425,y: -0.15)
            ],
            edges: [
                Edge(from: 0, to: 1),
                Edge(from: 1, to: 2),
                Edge(from: 2, to: 3),
                Edge(from: 3, to: 4),
                Edge(from: 4, to: 0)
            ]
        )
    ]
}

// Example of how to access a level:
// let firstLevel = Level.allLevels[0]
// let firstNodeOfFirstLevel = firstLevel.nodes[0]
// print("First level ('\(firstLevel.name)') first node: (\(firstNodeOfFirstLevel.x), \(firstNodeOfFirstLevel.y))")
