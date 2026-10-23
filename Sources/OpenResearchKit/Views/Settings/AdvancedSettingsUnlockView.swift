import SwiftUI

struct AdvancedSettingsUnlockView: View {
    let study: Study

    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var errorMessage: String?
    @FocusState private var isCodeFocused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField(text: $code) {
                        Text("Code", bundle: .module)
                    }
                    .keyboardType(.numberPad)
                    .focused($isCodeFocused)
                    .accessibilityIdentifier("advancedSettingsCode")
                } footer: {
                    Text("Enter the code to unlock the advanced settings.", bundle: .module)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("advancedSettingsCodeError")
                    }
                }
            }
            .navigationTitle(Text("Unlock advanced settings", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() } label: {
                        Text("Cancel", bundle: .module)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: unlock) {
                        Text("Unlock", bundle: .module)
                    }
                    .disabled(code.isEmpty)
                    .accessibilityIdentifier("advancedSettingsCodeSubmit")
                }
            }
            .onAppear { isCodeFocused = true }
        }
        .navigationViewStyle(.stack)
    }

    private func unlock() {
        do {
            try study.unlockAdvancedSettings(with: code)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            code = ""
        }
    }
}

#Preview {
    AdvancedSettingsUnlockView(
        study: Study(
            studyIdentifier: "preview",
            studyInformation: StudyInformation(title: "Example Study", subtitle: "", contactEmail: "info@example.org", image: nil),
            uploadConfiguration: .init(serverURL: URL(string: "https://example.org")!, uploadFrequency: 24 * 60 * 60, apiKey: ""),
            introductorySurveyURL: nil
        )
    )
}
