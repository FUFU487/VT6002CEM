import SwiftUI
import ARKit
import AVFoundation
import AudioToolbox
import Accelerate

struct ARView2: View {
    @State private var isARViewPresented = false
    
    var body: some View {
        VStack {
            Button(action: {
                self.isARViewPresented = true
            }) {
                Text("Start AR Experience")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .sheet(isPresented: $isARViewPresented) {
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    class Coordinator: NSObject {
        var parent: ARViewContainer
        var midiPlayer: AVMIDIPlayer?
        
        init(parent: ARViewContainer) {
            self.parent = parent
        }
        
        @objc func resetAR(_ sender: UIButton) {
            parent.resetARScene()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        let arView = ARSCNView()
        arView.frame = containerView.bounds
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.scene = SCNScene()
        
        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration)
        containerView.addSubview(arView)
        
        if let midiURL = getMIDIFileURLFromTmp() {
            processMIDIFile(midiURL, arView: arView, context: context)
        } else {
            print("MIDI file not found in tmp directory")
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func resetARScene() {
        print("Resetting AR scene...")
    }
    
    private func getMIDIFileURLFromTmp() -> URL? {
        let fileManager = FileManager.default
        let tmpDirectory = fileManager.temporaryDirectory
        let midiFileURL = tmpDirectory.appendingPathComponent("output.mid")
        return fileManager.fileExists(atPath: midiFileURL.path) ? midiFileURL : nil
    }
    
    private func processMIDIFile(_ url: URL, arView: ARSCNView, context: Context) {
        do {
            if let soundFontURL = Bundle.main.url(forResource: "FluidR3_GM", withExtension: "sf2") {
                context.coordinator.midiPlayer = try AVMIDIPlayer(contentsOf: url, soundBankURL: soundFontURL)
                context.coordinator.midiPlayer?.prepareToPlay()
                context.coordinator.midiPlayer?.play()
            } else {
                print("SoundFont file not found")
            }
            
            let midiData = try Data(contentsOf: url)
            let frequencies = extractFrequencies(from: midiData)
            DispatchQueue.main.async {
                self.displayDynamicWaveform(in: arView, frequencies: frequencies)
            }
        } catch {
            print("Failed to load MIDI file: \(error.localizedDescription)")
        }
    }
    
    private func extractFrequencies(from midiData: Data) -> [Float] {
        let sampleCount = 512
        var frequencies = [Float](repeating: 0.0, count: sampleCount)
        
        for i in 0..<sampleCount {
            frequencies[i] = sin(Float(i) * 0.1 + Float(Date().timeIntervalSince1970)) * (0.5 + Float.random(in: -0.2...0.2)) + 0.5
        }
        return frequencies
    }
    
    private func displayDynamicWaveform(in arView: ARSCNView, frequencies: [Float]) {
        DispatchQueue.main.async {
            arView.scene.rootNode.enumerateChildNodes { (node, _) in
                node.position.x -= 0.02 // 移動波形，使其由右向左移動
                if node.position.x < -5.0 {
                    node.removeFromParentNode()
                }
            }
            
            let waveformNode = SCNNode()
            waveformNode.position = SCNVector3(0, 0, -2) // 調整波形位置到正前方
            
            for (index, value) in frequencies.enumerated() {
                let barWidth: Float = 0.02
                let barHeight = CGFloat(value) * 0.5
                let barLength: Float = 0.02
                
                let box = SCNBox(width: CGFloat(barWidth), height: barHeight, length: CGFloat(barLength), chamferRadius: 0)
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.white
                box.materials = [material]
                
                let boxNode = SCNNode(geometry: box)
                boxNode.position = SCNVector3(Float(index) * barWidth - 5.0, Float(value) * 0.25, 0) // 調整位置，使波形顯示在正前方
                waveformNode.addChildNode(boxNode)
            }
            
            arView.scene.rootNode.addChildNode(waveformNode)
        }
    }
}

struct MIDIARApp: App {
    var body: some Scene {
        WindowGroup {
            ARView2()
        }
    }
}

#Preview {
    ARView2()
}
