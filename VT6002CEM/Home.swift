import SwiftUI
import AudioVisualizer
import QuickLook
import Transition

struct HomeView: View {
    @Bindable var manager: AudioManager
    @Bindable var settings: Settings

    @Environment(\.colorScheme) var colorScheme

    @State private var visNum: Int = 0
    @State private var enableSongFileSelection = false
    @State private var pauseButtonIsPaused = false

    @State private var userGuideUrl: URL?
    @State private var visualizationsGuideUrl: URL?

    @State private var showTopToolbar = true
    @State private var showBottomToolbar = true
    @State private var nextVis = true

    var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar
            if showTopToolbar {
                topToolbar
            }

            // Main Visualization Pane
            Group {
                visList[visNum].view
                    .transition(.crosswarp(rightToLeft: nextVis))
            }
            .navigationTitle("MuVis - Music Visualizer")
            .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                .onEnded { value in
                    switch(value.translation.width, value.translation.height) {
                    case (...0, -30...30): // Left swipe
                        withAnimation(.easeOut(duration: 1.618)) {
                            nextVis = true
                            visNum = (visNum + 1) % visList.count
                        }
                    case (0..., -30...30): // Right swipe
                        withAnimation(.easeOut(duration: 1.618)) {
                            nextVis = false
                            visNum = (visNum - 1 + visList.count) % visList.count
                        }
                    default:
                        break
                    }
                })
            .gesture(TapGesture(count: 3)
                .onEnded {
                    showTopToolbar.toggle()
                    showBottomToolbar.toggle()
                }
            )

            // Bottom Toolbar
            if showBottomToolbar {
                bottomToolbar
            }
        }
    }

    // Top Toolbar
    var topToolbar: some View {
        HStack {
            Text("Gain-")
                .padding(.leading)

            Slider(value: $manager.userGain, in: 0.0...8.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.red, lineWidth: 2)
                )
                .help("This slider controls the gain of the visualization.")
            
            Text("-Treble")
                .padding(.trailing)
        }
    }

    // Bottom Toolbar
    var bottomToolbar: some View {
        HStack {
            Button(action: {
                nextVis = false
                withAnimation(.easeOut(duration: 1.618)) {
                    visNum = (visNum - 1 + visList.count) % visList.count
                }
            }) {
                Image(systemName: "chevron.left")
            }

            Text("Vis: \(visNum)").font(.callout)

            Button(action: {
                nextVis = true
                withAnimation(.easeOut(duration: 1.618)) {
                    visNum = (visNum + 1) % visList.count
                }
            }) {
                Image(systemName: "chevron.right")
            }

            Spacer()

            Button(action: {
                if manager.isPaused {
                    manager.startMusicPlay()
                } else {
                    manager.pauseMusicPlay()
                }
                manager.isPaused.toggle()
                pauseButtonIsPaused.toggle()
            }) {
                pauseButtonIsPaused ? Image(systemName: "play.fill") : Image(systemName: "pause.fill")
            }
        }
    }
}
