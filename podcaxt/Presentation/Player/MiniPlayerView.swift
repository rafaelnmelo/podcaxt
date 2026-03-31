import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    @StateObject private var imageLoader = ImageLoader()
    @State private var isExpanded = false

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let image = imageLoader.image {
                    image.resizable().scaledToFill()
                } else {
                    Color.secondary.opacity(0.2)
                        .overlay(Image(systemName: SystemImage.mic))
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(viewModel.currentEpisode?.title ?? "")
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            Button(action: viewModel.togglePlayPause) {
                Image(systemName: viewModel.isPlaying ? SystemImage.pause : SystemImage.play)
                    .font(.title3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 12)
        .onTapGesture { isExpanded = true }
        .sheet(isPresented: $isExpanded) {
            NavigationStack {
                PlayerView()
            }
        }
        .task(id: viewModel.currentEpisode?.id) {
            await imageLoader.load(from: viewModel.currentEpisode?.imageURL)
        }
    }
}
