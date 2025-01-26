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

        // MIDI 文件头
        midiData.append(contentsOf: [0x4D, 0x54, 0x68, 0x64]) // "MThd"
        midiData.append(contentsOf: [0x00, 0x00, 0x00, 0x06]) // Header length
        midiData.append(contentsOf: [0x00, 0x00]) // Format type: 0 (single track)
        midiData.append(contentsOf: [0x00, 0x01]) // Number of tracks: 1
        midiData.append(contentsOf: [0x00, 0x60]) // Division: 96 ticks per quarter note

        // Track 数据
        var trackData = Data()
        trackData.append(contentsOf: [0x00, 0xFF, 0x03, 0x07]) // Track Name (可选)
        trackData.append(contentsOf: "Track 1".utf8)

        for note in notes {
            // 解析音符
            let components = note.split(separator: ",")
            guard components.count >= 2 else { continue }

            let pitch = components[0].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "Pitch: ", with: "")
            let durationString = components[1].trimmingCharacters(in: .whitespaces)
            guard let duration = Int(durationString.split(separator: ":").last ?? "") else { continue }

            // 将 Pitch 映射到 MIDI 数字
            if let midiNumber = pitchToMIDINumber(pitch: pitch) {
                // Note-On
                trackData.append(contentsOf: [0x00, 0x90, UInt8(midiNumber), 0x64]) // Velocity: 100
                // Note-Off
                trackData.append(contentsOf: [UInt8(duration), 0x80, UInt8(midiNumber), 0x40]) // Velocity: 64
            }
        }

        // 结束事件
        trackData.append(contentsOf: [0x00, 0xFF, 0x2F, 0x00]) // End of Track

        // 添加 Track 长度
        let trackLength = UInt32(trackData.count).bigEndian
        midiData.append(contentsOf: [0x4D, 0x54, 0x72, 0x6B]) // "MTrk"
        midiData.append(contentsOf: withUnsafeBytes(of: trackLength) { Array($0) })
        midiData.append(trackData)

        // 写入文件
        do {
            try midiData.write(to: midiFileURL)
            print("生成的 MIDI 文件路径: \(midiFileURL)")
        } catch {
            print("写入 MIDI 文件失败: \(error.localizedDescription)")
        }

        return midiFileURL
    }

    private func pitchToMIDINumber(pitch: String) -> Int? {
        let pitchMap: [String: Int] = [
            "C0": 12, "C#0": 13, "D0": 14, "D#0": 15, "E0": 16, "F0": 17, "F#0": 18, "G0": 19, "G#0": 20, "A0": 21, "A#0": 22, "B0": 23,
            "C1": 24, "C#1": 25, "D1": 26, "D#1": 27, "E1": 28, "F1": 29, "F#1": 30, "G1": 31, "G#1": 32, "A1": 33, "A#1": 34, "B1": 35,
            "C2": 36, "C#2": 37, "D2": 38, "D#2": 39, "E2": 40, "F2": 41, "F#2": 42, "G2": 43, "G#2": 44, "A2": 45, "A#2": 46, "B2": 47,
            "C3": 48, "C#3": 49, "D3": 50, "D#3": 51, "E3": 52, "F3": 53, "F#3": 54, "G3": 55, "G#3": 56, "A3": 57, "A#3": 58, "B3": 59,
            "C4": 60, "C#4": 61, "D4": 62, "D#4": 63, "E4": 64, "F4": 65, "F#4": 66, "G4": 67, "G#4": 68, "A4": 69, "A#4": 70, "B4": 71,
            "C5": 72, "C#5": 73, "D5": 74, "D#5": 75, "E5": 76, "F5": 77, "F#5": 78, "G5": 79, "G#5": 80, "A5": 81, "A#5": 82, "B5": 83,
            "C6": 84, "C#6": 85, "D6": 86, "D#6": 87, "E6": 88, "F6": 89, "F#6": 90, "G6": 91, "G#6": 92, "A6": 93, "A#6": 94, "B6": 95,
            "C7": 96, "C#7": 97, "D7": 98, "D#7": 99, "E7": 100, "F7": 101, "F#7": 102, "G7": 103, "G#7": 104, "A7": 105, "A#7": 106, "B7": 107,
            "C8": 108
        ]
        return pitchMap[pitch]
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
