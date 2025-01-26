import SwiftUI
import Foundation
import AVFoundation

struct Home: View {
    @State private var documentFiles: [String] = [] // 存储文件列表
    @State private var midiPlayer: AVMIDIPlayer? // 用于播放 MIDI

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("MusicXML Analyzer")
                .font(.largeTitle)
                .bold()

            Button(action: listDocumentFiles) {
                Text("List Files in Documents")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            List(documentFiles, id: \ .self) { file in
                Text(file)
                    .onTapGesture {
                        analyzeFile(named: file)
                    }
            }

            Spacer()
        }
        .padding()
    }

    private func listDocumentFiles() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first

        if let documentsURL = documentsURL {
            do {
                let files = try fileManager.contentsOfDirectory(atPath: documentsURL.path)
                documentFiles = files.filter { $0.hasSuffix(".musicxml") }
            } catch {
                documentFiles = ["Error: Could not load files"]
            }
        }
    }

    private func analyzeFile(named fileName: String) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileURL = documentsURL?.appendingPathComponent(fileName)

        guard let fileURL = fileURL else {
            print("Error: File not found")
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let parser = MusicXMLParser()
            parser.parseMusicXML(from: data)

            // 验证解析的音符数据
            print("解析的音符数据: \(parser.parsedNotes)")
            
            let midiFileURL = generateMIDI(from: parser.parsedNotes)
            if let soundFontURL = Bundle.main.url(forResource: "FluidR3_GM", withExtension: "sf2") {
                playMIDI(midiFileURL: midiFileURL, soundFontURL: soundFontURL)
            } else {
                print("Error: SoundFont file not found")
            }
        } catch {
            print("Error: Failed to read file")
        }
    }

    private func generateMIDI(from notes: [String]) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let midiFileURL = tempDirectory.appendingPathComponent("output.mid")

        var midiData = Data()

        // 写入 MIDI 文件头
        midiData.append(contentsOf: [0x4D, 0x54, 0x68, 0x64]) // "MThd"
        midiData.append(contentsOf: [0x00, 0x00, 0x00, 0x06]) // Header 长度 6 bytes
        midiData.append(contentsOf: [0x00, 0x00]) // Format type: 0 (单轨)
        midiData.append(contentsOf: [0x00, 0x01]) // Number of tracks: 1
        midiData.append(contentsOf: [0x00, 0x60]) // Division: 96 ticks per quarter note

        // 开始 Track 数据
        var trackData = Data()

        // 添加 Track 名称
        trackData.append(contentsOf: [0x00, 0xFF, 0x03, 0x07]) // Meta Event: Track name
        trackData.append(contentsOf: "Track 1".utf8)

        var currentTime: UInt32 = 0 // 当前时间（以 ticks 为单位）

        // 添加音符事件
        for note in notes {
            let components = note.split(separator: ",")
            guard components.count >= 3 else { continue }

            let pitch = components[0].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "Pitch: ", with: "")
            let durationString = components[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "Duration: ", with: "")
            guard let duration = Int(durationString) else { continue }

            if let midiNumber = pitchToMIDINumber(pitch: pitch) {
                // Note-On 事件
                trackData.append(contentsOf: deltaTimeBytes(for: currentTime))
                trackData.append(contentsOf: [0x90, UInt8(midiNumber), 0x64]) // Velocity: 100

                // Note-Off 事件
                let noteDurationTicks = UInt32(duration * 12) // 假设 duration 为 1/8 音符单位
                trackData.append(contentsOf: deltaTimeBytes(for: noteDurationTicks))
                trackData.append(contentsOf: [0x80, UInt8(midiNumber), 0x40]) // Velocity: 64

                // 更新当前时间
                currentTime = 0 // Note-On 后 delta time 重置为 0
            }
        }

        // 添加 Track 结束事件
        trackData.append(contentsOf: [0x00, 0xFF, 0x2F, 0x00]) // End of Track

        // 写入 Track 数据长度
        let trackLength = UInt32(trackData.count).bigEndian
        midiData.append(contentsOf: [0x4D, 0x54, 0x72, 0x6B]) // "MTrk"
        midiData.append(contentsOf: withUnsafeBytes(of: trackLength) { Array($0) })
        midiData.append(trackData)

        // 写入 MIDI 文件
        do {
            try midiData.write(to: midiFileURL)
            print("生成的 MIDI 文件路径: \(midiFileURL)")
        } catch {
            print("写入 MIDI 文件失败: \(error.localizedDescription)")
        }

        return midiFileURL
    }

    // 将 delta time 转换为可变长度的字节表示
    private func deltaTimeBytes(for deltaTime: UInt32) -> [UInt8] {
        var buffer = [UInt8]()
        var value = deltaTime

        repeat {
            var byte = UInt8(value & 0x7F)
            value >>= 7
            if !buffer.isEmpty { byte |= 0x80 } // 设置最高位
            buffer.insert(byte, at: 0)
        } while value > 0

        return buffer
    }

    // 将音高转换为 MIDI 数字编号
    private func pitchToMIDINumber(pitch: String) -> Int? {
        let pitchMap = [
            "C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6,
            "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11
        ]
        let octaveIndex = pitch.lastIndex(where: { $0.isNumber })
        guard let octaveIndex = octaveIndex, let octave = Int(String(pitch[octaveIndex...])) else { return nil }
        let note = String(pitch[..<octaveIndex])
        guard let semitone = pitchMap[note] else { return nil }
        return 12 * (octave + 1) + semitone
    }

    func playMIDI(midiFileURL: URL, soundFontURL: URL) {
        do {
            let midiPlayer = try AVMIDIPlayer(contentsOf: midiFileURL, soundBankURL: soundFontURL)
            self.midiPlayer = midiPlayer
            midiPlayer.prepareToPlay()
            midiPlayer.play {
                print("MIDI 播放完成")
            }
            print("MIDI 播放成功")
        } catch {
            print("播放 MIDI 文件失败: \(error.localizedDescription)")
        }
    }
}

struct MusicXMLView_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
