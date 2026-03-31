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
            .navigationTitle(Strings.App.title)
            .task { viewModel.loadHistory() }
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
            ForEach(viewModel.history, id: \.url) { feedURL in
                Button {
                    Task { await viewModel.select(feedURL) }
                } label: {
                    PodcastHistoryRowView(feedURL: feedURL, viewModel: viewModel)
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
        TextField(Strings.RSSInput.urlPlaceholder, text: $viewModel.urlText)
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
                    Text(Strings.RSSInput.loadButton)
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
            Text(Strings.RSSInput.recentHeader)
            Spacer()
            Button(Strings.RSSInput.clearButton, action: viewModel.clearHistory)
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
