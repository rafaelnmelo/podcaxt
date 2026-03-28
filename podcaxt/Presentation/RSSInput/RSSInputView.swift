import SwiftUI

struct RSSInputView: View {
    @StateObject private var viewModel = RSSInputViewModel()
    @State private var navigateToPodcast: Podcast?

    var body: some View {
        NavigationStack {
            List {
                inputSection
                if !viewModel.history.isEmpty {
                    historySection
                }
            }
            .navigationTitle("Podcaxt")
            .onAppear { viewModel.loadHistory() }
            .navigationDestination(item: $navigateToPodcast) { podcast in
                Text(podcast.title) // placeholder para PodcastDetailView
            }
        }
        .onChange(of: viewModel.state) { _, state in
            if case .success(let podcast) = state {
                navigateToPodcast = podcast
            }
        }
    }
}

// MARK: - Sections

private extension RSSInputView {
    var inputSection: some View {
        Section {
            TextField("https://feeds.example.com/podcast", text: $viewModel.urlText)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Button(action: { Task { await viewModel.submitURL() } }) {
                HStack {
                    Spacer()
                    if case .loading = viewModel.state {
                        ProgressView()
                    } else {
                        Text("Buscar Podcast")
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.urlText.isEmpty || isLoading)

            if case .failure(let message) = viewModel.state {
                Text(message)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    var historySection: some View {
        Section {
            ForEach(viewModel.history) { feedURL in
                Button(feedURL.url.absoluteString) {
                    Task { await viewModel.select(feedURL) }
                }
                .foregroundStyle(.primary)
            }
            .onDelete { indexSet in
                indexSet.map { viewModel.history[$0] }.forEach(viewModel.removeFromHistory)
            }
        } header: {
            HStack {
                Text("Recente")
                Spacer()
                Button("Limpar", action: viewModel.clearHistory)
                    .font(.caption)
            }
        }
    }

    var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }
}

#Preview {
    RSSInputView()
}
