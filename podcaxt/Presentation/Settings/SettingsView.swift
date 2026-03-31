import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            storageSection
        }
        .navigationTitle(Strings.Settings.navigationTitle)
        .onAppear { viewModel.loadCacheSize() }
        .confirmationDialog(
            Strings.Settings.clearCacheConfirmTitle,
            isPresented: $viewModel.showConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.Settings.clearCache, role: .destructive) { viewModel.clearCache() }
            Button(Strings.General.cancel, role: .cancel) {}
        } message: {
            Text(Strings.Settings.clearCacheConfirmMessage)
        }
        .alert(resultAlertTitle, isPresented: Binding(
            get: { viewModel.clearResult != nil },
            set: { if !$0 { viewModel.clearResult = nil } }
        )) {
            Button(Strings.General.ok, role: .cancel) {}
        } message: {
            Text(resultAlertMessage)
        }
    }

    private var resultAlertTitle: String {
        if case .failure = viewModel.clearResult { return Strings.Settings.clearCacheFailureTitle }
        return Strings.Settings.clearCacheSuccessTitle
    }

    private var resultAlertMessage: String {
        if case .failure(let message) = viewModel.clearResult { return message }
        return Strings.Settings.clearCacheSuccessMessage
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
            viewModel.showConfirmation = true
        } label: {
            Label(Strings.Settings.clearCache, systemImage: SystemImage.trash)
        }
        .disabled(viewModel.isClearing)
    }
}

#Preview {
    SettingsView()
}
