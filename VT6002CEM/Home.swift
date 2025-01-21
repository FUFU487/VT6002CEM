//
//  Home.swift
//  VT6002CEM
//
//  Created by Vincent on 14/1/2025.
//

import SwiftUI

struct Home: View {
    @State private var isUploading = false
    @State private var resultText = "Upload a music sheet image!"

    var body: some View {
        VStack {
            Button("Upload Image") {
                uploadImage()
            }
            .padding()
            .disabled(isUploading)

            Text(resultText)
                .padding()
        }
    }

    func uploadImage() {
        guard let url = URL(string: "http://127.0.0.1:5000/process") else {
            resultText = "Invalid server URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // 獲取本地圖片路徑
        let filePath = Bundle.main.path(forResource: "sample", ofType: "png")!
        let fileData = try! Data(contentsOf: URL(fileURLWithPath: filePath))

        // 構建請求體
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"sample.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        isUploading = true
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isUploading = false

                if let error = error {
                    resultText = "Upload failed: \(error.localizedDescription)"
                    return
                }

                resultText = "Upload successful! Check server output."
            }
        }.resume()
    }
}
