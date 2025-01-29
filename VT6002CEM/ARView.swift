//import SwiftUI
//import AVFoundation
//import ARKit
//
//struct ContentView: View {
//    @State private var midiFileURL: URL? = nil
//    @State private var audioWaveform: [Float] = []
//    @State private var showARView = false
//
//    var body: some View {
//        VStack {
//            Button("Select MIDI File") {
//                selectMIDIFile()
//            }
//            .padding()
//
//            if !audioWaveform.isEmpty {
//                WaveformView(waveform: audioWaveform)
//                    .frame(height: 200)
//                    .padding()
//            }
//
//            Button("Show in AR") {
//                showARView.toggle()
//            }
//            .padding()
//            .disabled(audioWaveform.isEmpty)
//        }
//        .sheet(isPresented: $showARView) {
//            ARWaveformView(waveform: audioWaveform)
//        }
//    }
//
//    private func selectMIDIFile() {
//        let panel = NSOpenPanel()
//        panel.allowedFileTypes = ["mid", "midi"]
//        panel.begin { response in
//            if response == .OK {
//                midiFileURL = panel.url
//                if let url = midiFileURL {
//                    processMIDIFile(url: url)
//                }
//            }
//        }
//    }
//
//    private func processMIDIFile(url: URL) {
//        // Convert MIDI to Audio
//        let audioEngine = AVAudioEngine()
//        let midiPlayer = AVMIDIPlayer(contentsOf: url, soundBankURL: nil)
//
//        midiPlayer.prepareToPlay()
//        midiPlayer.play()
//
//        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
//            // Simulate waveform (This needs actual audio processing, this is a placeholder)
//            DispatchQueue.main.async {
//                self.audioWaveform = (0..<100).map { _ in Float.random(in: -1...1) }
//            }
//        }
//    }
//}
//
//struct WaveformView: View {
//    let waveform: [Float]
//
//    var body: some View {
//        GeometryReader { geometry in
//            Path { path in
//                let midY = geometry.size.height / 2
//                let width = geometry.size.width / CGFloat(waveform.count)
//
//                for (index, value) in waveform.enumerated() {
//                    let x = CGFloat(index) * width
//                    let y = midY - CGFloat(value) * midY
//                    if index == 0 {
//                        path.move(to: CGPoint(x: x, y: y))
//                    } else {
//                        path.addLine(to: CGPoint(x: x, y: y))
//                    }
//                }
//            }
//            .stroke(Color.blue, lineWidth: 2)
//        }
//    }
//}
//
//struct ARWaveformView: UIViewControllerRepresentable {
//    let waveform: [Float]
//
//    func makeUIViewController(context: Context) -> ARViewController {
//        return ARViewController(waveform: waveform)
//    }
//
//    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
//}
//
//class ARViewController: UIViewController, ARSCNViewDelegate {
//    let waveform: [Float]
//    private var sceneView: ARSCNView!
//
//    init(waveform: [Float]) {
//        self.waveform = waveform
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        sceneView = ARSCNView(frame: self.view.frame)
//        sceneView.delegate = self
//        sceneView.scene = SCNScene()
//        self.view.addSubview(sceneView)
//
//        addWaveformToScene()
//    }
//
//    private func addWaveformToScene() {
//        let waveformNode = SCNNode()
//        let spacing: Float = 0.01
//
//        for (index, value) in waveform.enumerated() {
//            let bar = SCNBox(width: 0.01, height: CGFloat(abs(value)), length: 0.01, chamferRadius: 0)
//            let material = SCNMaterial()
//            material.diffuse.contents = UIColor.blue
//            bar.materials = [material]
//
//            let barNode = SCNNode(geometry: bar)
//            barNode.position = SCNVector3(Float(index) * spacing, value / 2, 0)
//
//            waveformNode.addChildNode(barNode)
//        }
//
//        sceneView.scene.rootNode.addChildNode(waveformNode)
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        let configuration = ARWorldTrackingConfiguration()
//        sceneView.session.run(configuration)
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        sceneView.session.pause()
//    }
//}
