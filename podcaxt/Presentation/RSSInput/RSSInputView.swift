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
                PodcastDetailView(podcast: podcast)
            }
        }
        .onAppear {
            viewModel.onSuccess = { podcast in
                navigateToPodcast = podcast
            }
        }
    }
}

// MARK: - Sections

private extension RSSInputView {
    var inputSection: some View {
        Section {
            urlTextField
            submitButton
            errorMessage
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
            historySectionHeader
        }
    }
}

// MARK: - Components

private extension RSSInputView {
    var urlTextField: some View {
        TextField("Cole uma URL de feed RSS ...", text: $viewModel.urlText)
            .keyboardType(.URL)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
    }

    var submitButton: some View {
        Button(action: { Task { await viewModel.submitURL() } }) {
            HStack {
                Spacer()
                if case .loading = viewModel.state {
                    ProgressView()
                } else {
                    Text("Carregar Podcast")
                }
                Spacer()
            }
        }
        .disabled(viewModel.urlText.isEmpty || isLoading)
    }

    @ViewBuilder
    var errorMessage: some View {
        if case .failure(let message) = viewModel.state {
            Text(message)
                .foregroundStyle(.red)
                .font(.caption)
        }
    }

    var historySectionHeader: some View {
        HStack {
            Text("Recente")
            Spacer()
            Button("Limpar", action: viewModel.clearHistory)
                .font(.caption)
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
