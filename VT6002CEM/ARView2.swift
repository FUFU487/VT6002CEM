import SwiftUI
import ARKit
import AVFoundation

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
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration)
        
        // Load MIDI file from tmp directory
        if let midiURL = getMIDIFileURLFromTmp() {
            do {
                let midiData = try Data(contentsOf: midiURL)
                let waveform = generateWaveform(from: midiData)
                displayWaveform(in: arView, waveform: waveform)
            } catch {
                print("Failed to load MIDI file: \(error.localizedDescription)")
            }
        } else {
            print("MIDI file not found in tmp directory")
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    private func getMIDIFileURLFromTmp() -> URL? {
        let fileManager = FileManager.default
        let tmpDirectory = fileManager.temporaryDirectory
        let midiFileURL = tmpDirectory.appendingPathComponent("output.mid") // 修改為 output.mid
        
        // Check if the file exists
        if fileManager.fileExists(atPath: midiFileURL.path) {
            return midiFileURL
        } else {
            return nil
        }
    }
    
    private func generateWaveform(from midiData: Data) -> [Float] {
        // Parse MIDI data and generate waveform
        var waveform: [Float] = []
        for i in 0..<500 {  // 增加到 500 個點，使波形更加細緻
            waveform.append(Float(sin(Double(i) * 0.03)))  // 減少步長讓波形更細膩
        }
        return waveform
    }
    
    private func displayWaveform(in arView: ARSCNView, waveform: [Float]) {
        let waveformNode = SCNNode()
        
        for (index, value) in waveform.enumerated() {
            let box = SCNBox(width: 0.02, height: CGFloat(value) * 0.5, length: 0.02, chamferRadius: 0)  // 讓模型更小
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.blue
            material.specular.contents = UIColor.white
            box.materials = [material]
            
            let boxNode = SCNNode(geometry: box)
            boxNode.position = SCNVector3(Float(index) * 0.03, Float(value) * 0.25, 0)  // 讓柱狀模型更緊湊
            waveformNode.addChildNode(boxNode)
        }
        
        arView.scene.rootNode.addChildNode(waveformNode)
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
