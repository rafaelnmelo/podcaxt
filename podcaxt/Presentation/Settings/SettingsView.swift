import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            storageSection
        }
        .navigationTitle(Strings.Settings.navigationTitle)
        .onAppear { viewModel.loadCacheSize() }
    }

    private var storageSection: some View {
        Section(Strings.Settings.storageSection) {
            cacheSizeRow
            clearCacheButton
        }
    }

    private var cacheSizeRow: some View {
        HStack {
            Label(Strings.Settings.cacheLabel, systemImage: SystemImage.internaldrive)
            Spacer()
            Text(viewModel.cacheSize)
                .foregroundStyle(.secondary)
        }
    }

    private var clearCacheButton: some View {
        Button(role: .destructive) {
            viewModel.clearCache()
        } label: {
            Label(Strings.Settings.clearCache, systemImage: SystemImage.trash)
        }
        .disabled(viewModel.isClearing)
    }
}

#Preview {
    SettingsView()
}
