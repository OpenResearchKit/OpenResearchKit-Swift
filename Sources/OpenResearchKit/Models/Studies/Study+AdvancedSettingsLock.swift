import Foundation

extension Study {

    /// Whether this study's advanced settings are locked on this device.
    ///
    /// Use this to protect advanced controls in custom study views. ``reset()`` restores ``isAdvancedSettingsLockedByDefault``.
    public var isAdvancedSettingsLocked: Bool {
        store.get(Keys.AdvancedSettingsLocked, type: Bool.self) ?? isAdvancedSettingsLockedByDefault
    }

    /// Locks the advanced settings. Has no effect when the study has no ``advancedSettingsUnlockCode``.
    public func lockAdvancedSettings() {
        guard advancedSettingsUnlockCode != nil else { return }
        setAdvancedSettingsLocked(true)
    }

    /// Unlocks the advanced settings if the code matches ``advancedSettingsUnlockCode``.
    public func unlockAdvancedSettings(with code: String) throws {
        guard let advancedSettingsUnlockCode else { throw AdvancedSettingsLockError.unlockCodeNotSet }
        guard code == advancedSettingsUnlockCode else { throw AdvancedSettingsLockError.incorrectCode }
        setAdvancedSettingsLocked(false)
    }

    private func setAdvancedSettingsLocked(_ isLocked: Bool) {
        store.update(Keys.AdvancedSettingsLocked, value: isLocked)
        publishChangesOnMain()
    }

}
