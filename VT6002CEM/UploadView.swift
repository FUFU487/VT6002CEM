//
//  ContentView 2.swift
//  VT6002CEM
//
//  Created by Vincent on 20/1/2025.
//

import SwiftUI
import UIKit

struct UploadView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var apiResponse: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("Oemer API File Processor")
                .font(.largeTitle)
                .bold()

            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else {
                Text("Select an image to process")
                    .foregroundColor(.gray)
            }

            Button(action: {
                isImagePickerPresented = true
            }) {
                Text("Select Image")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: uploadImage) {
                Text("Submit to API")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedImage == nil || isUploading)

            if isUploading {
                ProgressView(value: uploadProgress, total: 1.0)
                    .padding()
            }

            if let response = apiResponse {
                Text("API Response:")
                    .font(.headline)
                Text(response)
                    .font(.body)
                    .foregroundColor(.green)
                    .padding()
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }

    func uploadImage() {
        guard let selectedImage = selectedImage else { return }

        isUploading = true
        uploadProgress = 0.0

        let url = URL(string: "http://127.0.0.1:5000/process-image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 300 // 设置超时为 300 秒 (5 分钟)

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let imageData = selectedImage.jpegData(compressionQuality: 0.8)!
        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            DispatchQueue.main.async {
                isUploading = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    apiResponse = "Error: \(error.localizedDescription)"
                }
                return
            }

            if let data = data, let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let musicxmlPath = jsonResponse["musicxml_path"] as? String {

                DispatchQueue.main.async {
                    apiResponse = "Success: File saved successfully in the app!"
                }

                // Save the MusicXML file in the app
                saveToAppDirectory(from: musicxmlPath)
            } else {
                DispatchQueue.main.async {
                    apiResponse = "Error: Invalid response from server"
                }
            }
        }.resume()
    }

    func saveToAppDirectory(from path: String) {
        guard let fileURL = URL(string: "http://127.0.0.1:5000/\(path)") else {
            DispatchQueue.main.async {
                apiResponse = "Error: Invalid file URL"
            }
            return
        }

        URLSession.shared.downloadTask(with: fileURL) { location, response, error in
            if let location = location {
                do {
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    var destinationURL = documentsURL.appendingPathComponent(fileURL.lastPathComponent)

                    // 如果文件已存在，则在名称后添加数字递增后缀
                    var counter = 1
                    while FileManager.default.fileExists(atPath: destinationURL.path) {
                        let fileName = fileURL.deletingPathExtension().lastPathComponent
                        let fileExtension = fileURL.pathExtension
                        destinationURL = documentsURL.appendingPathComponent("\(fileName)_\(counter).\(fileExtension)")
                        counter += 1
                    }

                    try FileManager.default.moveItem(at: location, to: destinationURL)
                } catch {
                    DispatchQueue.main.async {
                        apiResponse = "Error saving file: \(error.localizedDescription)"
                    }
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    apiResponse = "Download error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct OemerApp: App {
    var body: some Scene {
        WindowGroup {
            UploadView()
        }
    }
}

struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        UploadView()
    }
}
