import SwiftUI

struct AdvancedSettingsLockButton: View {
    let lock: () -> Void

    @State private var showConfirmation = false

    var body: some View {
        Button {
            showConfirmation = true
        } label: {
            Label {
                Text("Lock advanced settings", bundle: .module)
            } icon: {
                Image(systemName: "lock.open.fill")
            }
        }
        .accessibilityIdentifier("advancedSettingsLockButton")
        .alert(Text("Lock advanced settings?", bundle: .module), isPresented: $showConfirmation) {
            Button {
                lock()
            } label: {
                Text("Lock", bundle: .module)
            }
            .accessibilityIdentifier("confirmAdvancedSettingsLockButton")
            Button(role: .cancel) { } label: {
                Text("Cancel", bundle: .module)
            }
        } message: {
            Text("You will need the study code to unlock these settings again.", bundle: .module)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isLocked = false

    NavigationStack {
        Text(verbatim: isLocked ? "Settings locked" : "Settings unlocked")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !isLocked {
                        AdvancedSettingsLockButton { isLocked = true }
                    }
                }
            }
    }
}
