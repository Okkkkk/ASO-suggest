import SwiftUI

// Define custom colors
extension Color {
    static let primaryBlue = Color(red: 74/255, green: 158/255, blue: 255/255) // #4A9EFF
    static let adsRed = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    static let buttonBackground = Color(UIColor.systemGray5) // Standard system gray
    static let completedGreen = Color.green
    static let pathOrange = Color.orange
    static let startNodeYellow = Color.yellow
}

// Custom Button Style for pressed effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}


// Reusable button view - now applying the custom style
struct CircularButtonView<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    let foregroundColor: Color
    let frameSize: CGFloat
    let action: () -> Void

    init(backgroundColor: Color = .buttonBackground, foregroundColor: Color = .primary, frameSize: CGFloat, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.frameSize = frameSize
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            content
                .frame(width: frameSize, height: frameSize)
                .foregroundColor(foregroundColor)
                .background(backgroundColor)
                .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle()) // Apply custom button style
    }
}

struct ContentView: View {
    @State private var currentLevelIndex: Int = 0
    
    // Drawing interaction
    @State private var isDrawing: Bool = false
    @State private var currentPathNodeIndices: [Int] = []
    @State private var completedEdgeKeys: Set<String> = []
    @State private var currentDragPosition: CGPoint? = nil
    @State private var canvasGeoSize: CGSize = .zero 
    
    // Alerts and Hints
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var hintCount: Int = 2 

    // Animation States
    @State private var showingSuccessMessage: Bool = false
    @State private var successMessageScale: CGFloat = 0.5
    @State private var shakeOffset: CGFloat = 0
    @State private var showFailureIndicator: Bool = false
    @State private var failureIndicatorScale: CGFloat = 0.3
    @State private var failureIndicatorRotation: Angle = .degrees(-180)
    @State private var failureIndicatorOpacity: Double = 0

    let nodeRadius: CGFloat = 18
    let nodeHitThreshold: CGFloat = 36 

    var currentLevel: Level {
        Level.allLevels[currentLevelIndex]
    }

    func triggerShakeAnimation() {
        let duration = 0.08
        let displacement: CGFloat = 10
        withAnimation(.linear(duration: duration)) { shakeOffset = -displacement }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.linear(duration: duration)) { shakeOffset = displacement }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation(.linear(duration: duration)) { shakeOffset = -displacement / 2 }
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation(.linear(duration: duration)) { shakeOffset = displacement / 2 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation(.linear(duration: duration)) { shakeOffset = 0 }
                    }
                }
            }
        }
    }

    func triggerFailureIndicatorAnimation() {
        showFailureIndicator = true
        failureIndicatorScale = 0.3
        failureIndicatorRotation = .degrees(-180)
        failureIndicatorOpacity = 1.0

        withAnimation(.interpolatingSpring(stiffness: 170, damping: 8).speed(0.8)) {
            failureIndicatorScale = 1.0 
            failureIndicatorRotation = .degrees(0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { // Match animation duration
            withAnimation(.easeOut(duration: 0.3)) {
                failureIndicatorOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showFailureIndicator = false
                // Reset for next time
                failureIndicatorScale = 0.3
                failureIndicatorRotation = .degrees(-180)
            }
        }
    }

    func resetCurrentLevelProgress(failedAttempt: Bool = false) {
        if failedAttempt && !currentPathNodeIndices.isEmpty { // Trigger animations only if a path was started
            triggerShakeAnimation()
            triggerFailureIndicatorAnimation()
        }
        currentPathNodeIndices = []
        completedEdgeKeys = []
        isDrawing = false
        currentDragPosition = nil
    }

    func checkWinCondition() {
        if completedEdgeKeys.count == currentLevel.edges.count {
            handleLevelCompletion()
        }
    }

    func handleLevelCompletion() {
        showingSuccessMessage = true
        successMessageScale = 0.5 // Reset before animating
        withAnimation(.interpolatingSpring(mass: 0.5, stiffness: 100, damping: 10, initialVelocity: 0)) {
            successMessageScale = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showingSuccessMessage = false
            successMessageScale = 0.5 // Reset for next time
            loadNextLevel()
        }
    }

    func loadNextLevel() {
        currentLevelIndex = (currentLevelIndex + 1) % Level.allLevels.count
        resetCurrentLevelProgress() // No failure on normal level load
    }
    
    func scalePoint(node: Node, scale: CGFloat, offsetX: CGFloat, offsetY: CGFloat) -> CGPoint {
        let scaledX = node.x * scale + offsetX
        let scaledY = node.y * scale + offsetY
        return CGPoint(x: scaledX, y: scaledY)
    }

    func findNearestNode(at point: CGPoint, canvasSize: CGSize) -> Int? {
        guard canvasSize != .zero else { return nil }
        let scaleFactor = min(canvasSize.width, canvasSize.height) * 0.9
        let offsetX = canvasSize.width / 2
        let offsetY = canvasSize.height / 2

        for (index, node) in currentLevel.nodes.enumerated() {
            let nodeScreenPos = scalePoint(node: node, scale: scaleFactor, offsetX: offsetX, offsetY: offsetY)
            let distance = sqrt(pow(point.x - nodeScreenPos.x, 2) + pow(point.y - nodeScreenPos.y, 2))
            if distance < nodeHitThreshold {
                return index
            }
        }
        return nil
    }

    func isValidEdge(from fromIndex: Int, to toIndex: Int) -> Bool {
        currentLevel.edges.contains { edge in
            (edge.from == fromIndex && edge.to == toIndex) || (edge.from == toIndex && edge.to == fromIndex)
        }
    }
    
    func edgeKey(from: Int, to: Int) -> String {
        return "\(min(from, to))-\(max(from, to))"
    }

    var body: some View {
        ZStack { 
            VStack {
                // Header UI
                HStack {
                    Rectangle().frame(width: 50, height: 50).opacity(0)
                    Spacer()
                    VStack {
                        Text("Level")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primaryBlue)
                        Text("\(currentLevel.name)") 
                            .font(.system(size: 42, weight: .heavy))
                            .foregroundColor(.primaryBlue)
                            .lineLimit(1).minimumScaleFactor(0.5)
                    }.frame(minWidth: 100)
                    Spacer()
                    CircularButtonView(frameSize: 50, action: { 
                        alertTitle = "Settings"
                        alertMessage = "Settings functionality not yet implemented."
                        showingAlert = true
                    }) {
                        Image(systemName: "gearshape.fill").resizable().aspectRatio(contentMode: .fit).padding(12)
                    }.padding(.trailing)
                }.padding(.horizontal).padding(.top)

                // Game Area
                ZStack { // ZStack for Canvas and Failure Indicator
                    GeometryReader { geometry in
                        Canvas { context, size in
                            let scaleFactor = min(size.width, size.height) * 0.9
                            let offsetX = size.width / 2
                            let offsetY = size.height / 2

                            // Drawing logic (edges, nodes, dynamic line) remains the same
                            // ... Default Edges ...
                            for edge in currentLevel.edges {
                                let key = edgeKey(from: edge.from, to: edge.to)
                                if !completedEdgeKeys.contains(key) {
                                    guard currentLevel.nodes.indices.contains(edge.from),
                                          currentLevel.nodes.indices.contains(edge.to) else { continue }
                                    let fromNode = currentLevel.nodes[edge.from]
                                    let toNode = currentLevel.nodes[edge.to]
                                    let startPoint = scalePoint(node: fromNode, scale: scaleFactor, offsetX: offsetX, offsetY: offsetY)
                                    let endPoint = scalePoint(node: toNode, scale: scaleFactor, offsetX: offsetX, offsetY: offsetY)
                                    var path = Path()
                                    path.move(to: startPoint)
                                    path.addLine(to: endPoint)
                                    context.stroke(path, with: .color(Color.gray), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                }
                            }
                            // ... Completed Edges ...
                            for edgeKeyString in completedEdgeKeys {
                                let indices = edgeKeyString.split(separator: "-").map { Int($0)! }
                                guard indices.count == 2,
                                      currentLevel.nodes.indices.contains(indices[0]),
                                      currentLevel.nodes.indices.contains(indices[1]) else { continue }
                                let fromNode = currentLevel.nodes[indices[0]]
                                let toNode = currentLevel.nodes[indices[1]]
                                let startPoint = scalePoint(node: fromNode, scale: scaleFactor, offsetX: offsetX, offsetY: offsetY)
                                let endPoint = scalePoint(node: toNode, scale: scaleFactor, offsetX: offsetX, offsetY: offsetY)
                                var path = Path()
                                path.move(to: startPoint)
                                path.addLine(to: endPoint)
                                context.stroke(path, with: .color(Color.completedGreen), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            }
                            // ... Dynamic Line ...
                            if isDrawing, let lastNodeIndex = currentPathNodeIndices.last, let dragPos = currentDragPosition {
                                if currentLevel.nodes.indices.contains(lastNodeIndex) {
                                    let lastNode = currentLevel.nodes[lastNodeIndex]
                                    let startPoint = scalePoint(node: lastNode, scale: scaleFactor, offsetX: offsetX, offsetY: offsetY)
                                    var path = Path()
                                    path.move(to: startPoint)
                                    path.addLine(to: dragPos)
                                    context.stroke(path, with: .color(Color.blue.opacity(0.5)), style: StrokeStyle(lineWidth: 12, lineCap: .round, dash: [10, 5]))
                                }
                            }
                            // ... Nodes ...
                            for (index, node) in currentLevel.nodes.enumerated() {
                                let nodeCenter = scalePoint(node: node, scale: scaleFactor, offsetX: offsetX, offsetY: offsetY)
                                let nodeRect = CGRect(x: nodeCenter.x - nodeRadius, y: nodeCenter.y - nodeRadius, width: nodeRadius * 2, height: nodeRadius * 2)
                                let nodePath = Path(ellipseIn: nodeRect)
                                var fillColor = Color.primaryBlue
                                if currentPathNodeIndices.contains(index) {
                                    fillColor = (index == currentPathNodeIndices.first) ? Color.startNodeYellow : Color.pathOrange
                                }
                                context.fill(nodePath, with: .color(fillColor))
                                context.stroke(nodePath, with: .color(Color.black), lineWidth: 2)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if self.canvasGeoSize == .zero { self.canvasGeoSize = geometry.size }
                                    self.currentDragPosition = value.location
                                    if !isDrawing {
                                        if let startNodeIndex = findNearestNode(at: value.startLocation, canvasSize: self.canvasGeoSize) {
                                            isDrawing = true
                                            currentPathNodeIndices = [startNodeIndex]
                                        }
                                    } else {
                                        if let lastNodeIndex = currentPathNodeIndices.last,
                                           let newNodeIndex = findNearestNode(at: value.location, canvasSize: self.canvasGeoSize) {
                                            if newNodeIndex != lastNodeIndex {
                                                let key = edgeKey(from: lastNodeIndex, to: newNodeIndex)
                                                if isValidEdge(from: lastNodeIndex, to: newNodeIndex) && !completedEdgeKeys.contains(key) {
                                                    currentPathNodeIndices.append(newNodeIndex)
                                                    completedEdgeKeys.insert(key)
                                                    checkWinCondition() 
                                                }
                                            }
                                        }
                                    }
                                }
                                .onEnded { value in
                                    isDrawing = false
                                    currentDragPosition = nil
                                    if completedEdgeKeys.count < currentLevel.edges.count && !currentPathNodeIndices.isEmpty {
                                        resetCurrentLevelProgress(failedAttempt: true) // Pass true for failure
                                    } else if !currentPathNodeIndices.isEmpty { 
                                        // Path was started but didn't result in a win or loss (e.g. drawing off screen)
                                        // We might want to reset without animations here, or just leave the path.
                                        // For now, let's reset without animations if it's not a win.
                                        if completedEdgeKeys.count < currentLevel.edges.count {
                                           resetCurrentLevelProgress(failedAttempt: false)
                                        }
                                    }
                                    // If currentPathNodeIndices is empty (just a tap), do nothing on .onEnded
                                }
                        )
                        .onAppear { self.canvasGeoSize = geometry.size }
                        .onChange(of: geometry.size) { newSize in self.canvasGeoSize = newSize }
                    } // End GeometryReader

                    // Failure Indicator "✕"
                    if showFailureIndicator {
                        Text("✕")
                            .font(.system(size: 80, weight: .bold)) // Increased size
                            .foregroundColor(.red)
                            .scaleEffect(failureIndicatorScale)
                            .rotationEffect(failureIndicatorRotation)
                            .opacity(failureIndicatorOpacity)
                            // Positioned in the center by ZStack default alignment
                    }
                } // End ZStack for Canvas and Failure Indicator
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure ZStack takes space


                // Bottom Controls UI
                HStack(spacing: 20) {
                    CircularButtonView(foregroundColor: .yellow, frameSize: 70, action: {
                        if hintCount > 0 {
                            hintCount -= 1
                            alertTitle = "💡 Hint"
                            alertMessage = "Look for nodes with an odd number of connections - these are often good starting/ending points!"
                        } else {
                            alertTitle = "Out of Hints"
                            alertMessage = "You have no more hints left! 😔"
                        }
                        showingAlert = true
                    }) {
                        Image(systemName: "lightbulb.fill").resizable().aspectRatio(contentMode: .fit).padding(18)
                    }

                    ZStack(alignment: .topTrailing) {
                        CircularButtonView(frameSize: 70, action: { 
                            alertTitle = "Remove Ads"
                            alertMessage = "Remove Ads functionality not yet implemented."
                            showingAlert = true
                        }) {
                            Text("ADS").font(.system(size: 20, weight: .bold)).foregroundColor(.adsRed)
                        }
                        if hintCount > 0 {
                            Text("\(hintCount)")
                                .font(.system(size: 12, weight: .bold)).foregroundColor(.black).padding(5)
                                .background(Color.yellow).clipShape(Circle()).offset(x: 5, y: -5)
                        }
                    }

                    CircularButtonView(foregroundColor: .primaryBlue, frameSize: 80, action: {
                        loadNextLevel()
                    }) {
                        Image(systemName: "arrow.right.circle.fill").resizable().aspectRatio(contentMode: .fit).padding(18)
                    }
                }.padding(.horizontal).padding(.bottom)
            }
            .offset(x: shakeOffset) // Apply shake offset to the entire game content VStack
            .disabled(showingSuccessMessage) 
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }

            // Success Message Overlay
            if showingSuccessMessage {
                VStack {
                    Spacer()
                    Text("Level Complete!")
                        .font(.largeTitle).fontWeight(.bold).padding()
                        .background(Color.green.opacity(0.8)).foregroundColor(.white).cornerRadius(10)
                        .scaleEffect(successMessageScale) // Apply scale animation
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.3))
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
