import Foundation

// MARK: - Model: MusicXMLParser
class MusicXMLParser: NSObject, XMLParserDelegate {
    var parsedNotes: [String] = [] // 用于存储解析的音符数据

    private var currentElement: String = ""
    private var currentNote: [String: String] = [:] // 当前音符信息

    /// 解析传入的 MusicXML 数据
    /// - Parameter data: XML 格式的 Data 对象
    func parseMusicXML(from data: Data) {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }

    // MARK: - XMLParserDelegate Methods

    /// 开始解析某个元素时调用
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        currentElement = elementName

        if elementName == "note" {
            currentNote = [:] // 初始化当前音符信息
        }
    }

    /// 读取元素的值时调用
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }

        if currentElement == "step" || currentElement == "octave" || currentElement == "duration" || currentElement == "type" {
            currentNote[currentElement] = value
        }
    }

    /// 结束解析某个元素时调用
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "note" {
            // 当音符结束时，将解析结果存储为字符串描述
            if let step = currentNote["step"], let octave = currentNote["octave"], let duration = currentNote["duration"], let type = currentNote["type"] {
                let noteDescription = "Pitch: \(step)\(octave), Duration: \(duration), Type: \(type)"
                parsedNotes.append(noteDescription)
            }
        }

        currentElement = ""
    }

    /// 解析结束时调用
    func parserDidEndDocument(_ parser: XMLParser) {
        print("Parsing completed! Parsed Notes:")
        print(parsedNotes)
    }

    /// 解析过程中遇到错误时调用
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("Error occurred: \(parseError.localizedDescription)")
    }
}
