import SwiftUI
import AVFoundation

struct Home: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var midiPlayer: AVMIDIPlayer?
    @State private var currentFileName: String?
    @State private var musicFiles: [String] = []
    @State private var isPlaying: Bool = false
    @State private var musicXMLContent: String = ""

    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(musicFiles, id: \ .self) { fileName in
                            Button(action: {
                                if fileName.hasSuffix(".musicxml") {
                                    playMusicXML(fileName: fileName)
                                } else {
                                    playAudio(fileName: fileName)
                                }
                            }) {
                                VStack {
                                    Image(systemName: currentFileName == fileName && isPlaying ? "play.circle.fill" : "music.note")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(currentFileName == fileName ? .blue : .gray)
                                    Text(fileName)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Music Player")

                Spacer()

                if let currentFileName = currentFileName {
                    VStack {
                        Text("Now Playing: \(currentFileName)")
                            .font(.headline)
                        HStack {
                            Button(action: {
                                stopPlayback()
                            }) {
                                Image(systemName: "stop.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.red)
                            }

                            Button(action: {
                                togglePlayPause()
                            }) {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding()
                }

                if !musicXMLContent.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading) {
                            if musicXMLContent.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<?xml") {
                                Text(musicXMLContent)
                                    .font(.body)
                                    .padding()
                            } else {
                                Text("Error: 文件不是有效的 MusicXML 格式。")
                                    .font(.body)
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                    }
                }

                Spacer()
            }
            .onAppear {
                loadFiles()
            }
        }
    }

    func playAudio(fileName: String) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.play()
            currentFileName = fileName
            isPlaying = true
        } catch {
            print("无法播放文件 \(fileName): \(error.localizedDescription)")
        }
    }

    func playMusicXML(fileName: String) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)

        configureAudioSession()

        do {
            let xmlData = try Data(contentsOf: fileURL)
            let parser = MusicXMLParser(data: xmlData)
            let midiData = try parser.parseToMIDI()
            let midiURL = documentsURL.appendingPathComponent("temp.mid")
            try midiData.write(to: midiURL)
            print("MIDI 文件生成成功: \(midiURL)")

            guard let soundFontURL = Bundle.main.url(forResource: "FluidR3_GM", withExtension: "sf2") else {
                print("Error: SoundFont 文件未找到。")
                return
            }
            print("SoundFont 文件路径: \(soundFontURL)")

            midiPlayer = try AVMIDIPlayer(contentsOf: midiURL, soundBankURL: soundFontURL)
            midiPlayer?.prepareToPlay()
            midiPlayer?.play {
                self.isPlaying = false
                print("播放完成")
            }

            currentFileName = fileName
            isPlaying = true
        } catch let error as NSError {
            print("无法播放 MusicXML 文件 \(fileName): \(error.localizedDescription) (code: \(error.code))")
            if let userInfo = error.userInfo as? [String: Any] {
                print("详细错误信息: \(userInfo)")
            }
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        midiPlayer?.stop()
        isPlaying = false
    }

    func togglePlayPause() {
        if let player = audioPlayer {
            if player.isPlaying {
                player.pause()
                isPlaying = false
            } else {
                player.play()
                isPlaying = true
            }
        } else if let player = midiPlayer {
            if isPlaying {
                player.stop()
                isPlaying = false
            } else {
                player.play()
                isPlaying = true
            }
        }
    }

    func loadFiles() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            musicFiles = urls.map { $0.lastPathComponent }
        } catch {
            print("Error loading files: \(error.localizedDescription)")
        }
    }

    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("音频会话已配置成功")
        } catch {
            print("音频会话配置失败: \(error.localizedDescription)")
        }
    }
}

class MusicXMLParser: NSObject, XMLParserDelegate {
    private var data: Data
    private var notes: [MIDINote] = []

    init(data: Data) {
        self.data = data
    }

    func parseToMIDI() throws -> Data {
        let parser = XMLParser(data: data)
        parser.delegate = self
        if parser.parse() {
            return generateMIDIData()
        } else {
            throw parser.parserError ?? NSError(domain: "MusicXMLParserError", code: -1, userInfo: nil)
        }
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "note" {
            var noteNumber: UInt8 = 60 // Default to middle C
            var velocity: UInt8 = 64   // Default velocity
            var duration: TimeInterval = 1.0 // Default duration
            var startTime: TimeInterval = 0.0 // Default start time

            if let pitch = attributeDict["pitch"], let midiValue = UInt8(pitch) {
                noteNumber = midiValue
            }
            if let dyn = attributeDict["velocity"], let velocityValue = UInt8(dyn) {
                velocity = velocityValue
            }
            if let dur = attributeDict["duration"], let durationValue = Double(dur) {
                duration = durationValue
            }
            if let start = attributeDict["startTime"], let startTimeValue = Double(start) {
                startTime = startTimeValue
            }

            notes.append(MIDINote(noteNumber: noteNumber, velocity: velocity, duration: duration, startTime: startTime))
        }
    }

    private func generateMIDIData() -> Data {
        let midiHeader: [UInt8] = [
            0x4D, 0x54, 0x68, 0x64, // "MThd"
            0x00, 0x00, 0x00, 0x06, // Header length
            0x00, 0x01,             // Format type
            0x00, 0x01,             // Number of tracks
            0x00, 0x60              // Division (ticks per quarter note)
        ]

        var midiEvents: [UInt8] = []
        var lastEventTime: TimeInterval = 0.0 // 用於追蹤上一個事件的時間

        for note in notes {
            let deltaTime = UInt8(max((note.startTime - lastEventTime) * 96, 0)) // 防止负值
            lastEventTime = note.startTime + note.duration

            midiEvents.append(contentsOf: [
                deltaTime,              // Delta time
                0x90,                   // Note On event
                note.noteNumber,        // Note number
                note.velocity           // Velocity
            ])

            midiEvents.append(contentsOf: [
                UInt8(note.duration * 96), // 持續時間轉換為 Delta Time
                0x80,                      // Note Off event
                note.noteNumber,           // Note number
                0x40                       // Velocity
            ])
        }
        midiEvents.append(contentsOf: [0x00, 0xFF, 0x2F, 0x00]) // 結束事件

        let trackLength = midiEvents.count
        let trackHeader: [UInt8] = [
            0x4D, 0x54, 0x72, 0x6B, // "MTrk"
            UInt8((trackLength >> 24) & 0xFF),
            UInt8((trackLength >> 16) & 0xFF),
            UInt8((trackLength >> 8) & 0xFF),
            UInt8(trackLength & 0xFF)
        ]

        print("Track Length: \(trackLength)")

        return Data(midiHeader + trackHeader + midiEvents)
    }
}

struct MIDINote {
    var noteNumber: UInt8
    var velocity: UInt8
    var duration: TimeInterval
    var startTime: TimeInterval // 添加開始時間屬性
}

#Preview {
    Home()
}
