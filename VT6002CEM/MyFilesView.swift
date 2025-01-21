//
//  MyFilesView.swift
//  VT6002CEM
//
//  Created by Vincent on 22/1/2025.
//

import SwiftUI
import UIKit

struct MyFilesView: View {
    @State private var files: [URL] = []
    @State private var selectedFile: URL? = nil
    @State private var isRenaming = false
    @State private var newFileName: String = ""

    var body: some View {
        NavigationView {
            VStack {
                if files.isEmpty {
                    Text("No files available.")
                        .foregroundColor(.gray)
                } else {
                    List(files, id: \..self) { file in
                        HStack {
                            Text(file.lastPathComponent)
                                .onTapGesture {
                                    selectedFile = file
                                    newFileName = file.deletingPathExtension().lastPathComponent
                                    isRenaming = true
                                }

                            Spacer()

                            Button(action: {
                                uploadToICloud(file: file)
                            }) {
                                Image(systemName: "icloud.and.arrow.up")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Files")
            .onAppear(perform: loadFiles)
            .sheet(isPresented: $isRenaming) {
                NavigationView {
                    VStack(spacing: 20) {
                        TextField("New File Name", text: $newFileName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()

                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Rename File")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                isRenaming = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                if let file = selectedFile {
                                    renameFile(file: file, newName: newFileName)
                                }
                                isRenaming = false
                            }
                        }
                    }
                }
            }
        }
    }

    func loadFiles() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            files = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        } catch {
            print("Error loading files: \(error.localizedDescription)")
        }
    }

    func renameFile(file: URL, newName: String) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let newURL = documentsURL.appendingPathComponent(newName).appendingPathExtension(file.pathExtension)
        do {
            try FileManager.default.moveItem(at: file, to: newURL)
            loadFiles()
        } catch {
            print("Error renaming file: \(error.localizedDescription)")
        }
    }

    func uploadToICloud(file: URL) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [file])
        UIApplication.shared.windows.first?.rootViewController?.present(documentPicker, animated: true, completion: nil)
    }
}

struct MyFilesView_Previews: PreviewProvider {
    static var previews: some View {
        MyFilesView()
    }
}
