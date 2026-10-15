import Combine
import XCTest
@testable import OpenResearchKit

final class StudyAdvancedSettingsLockTests: XCTestCase {
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "OpenResearchKit.AdvancedSettingsLockTests.\(UUID().uuidString)"
    }

    override func tearDown() {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testDefaultLockStateAppliesUntilLockedOrUnlocked() throws {
        XCTAssertFalse(makeStudy(isLockedByDefault: false).isAdvancedSettingsLocked)
        let study = makeStudy(isLockedByDefault: true)
        XCTAssertTrue(study.isAdvancedSettingsLocked)
        try study.unlockAdvancedSettings(with: "000001")
        XCTAssertFalse(study.isAdvancedSettingsLocked)
    }

    func testStudyWithoutUnlockCodeCannotBeLockedOrUnlocked() {
        let lockedStudy = makeStudy(unlockCode: nil, isLockedByDefault: true)
        XCTAssertThrowsError(try lockedStudy.unlockAdvancedSettings(with: "")) {
            XCTAssertEqual($0 as? AdvancedSettingsLockError, .unlockCodeNotSet)
        }
        XCTAssertTrue(lockedStudy.isAdvancedSettingsLocked)

        let unlockedStudy = makeStudy(unlockCode: nil)
        unlockedStudy.lockAdvancedSettings()
        XCTAssertFalse(unlockedStudy.isAdvancedSettingsLocked)
    }

    func testOnlyMatchingCodeUnlocks() throws {
        let study = makeStudy()
        study.lockAdvancedSettings()
        XCTAssertTrue(study.isAdvancedSettingsLocked)
        XCTAssertThrowsError(try study.unlockAdvancedSettings(with: "000002")) {
            XCTAssertEqual($0 as? AdvancedSettingsLockError, .incorrectCode)
        }
        XCTAssertTrue(study.isAdvancedSettingsLocked)
        try study.unlockAdvancedSettings(with: "000001")
        XCTAssertFalse(study.isAdvancedSettingsLocked)
    }

    func testLockStatePersistsAcrossInstancesAndBuildTypes() throws {
        makeStudy().lockAdvancedSettings()
        let releaseStudy = makeStudy(isLockedByDefault: true)
        XCTAssertTrue(releaseStudy.isAdvancedSettingsLocked)
        try releaseStudy.unlockAdvancedSettings(with: "000001")
        XCTAssertFalse(makeStudy(isLockedByDefault: true).isAdvancedSettingsLocked)
    }

    func testStudiesHaveSeparateLockStates() {
        let first = makeStudy(identifier: "first")
        let second = makeStudy(identifier: "second")
        first.lockAdvancedSettings()
        XCTAssertTrue(first.isAdvancedSettingsLocked)
        XCTAssertFalse(second.isAdvancedSettingsLocked)
    }

    func testResetRestoresDefaultLockState() throws {
        let study = makeStudy(isLockedByDefault: true)
        try study.unlockAdvancedSettings(with: "000001")
        try study.reset()
        XCTAssertTrue(study.isAdvancedSettingsLocked)
    }

    func testLockChangesPublishAndGateDataActions() async throws {
        let study = makeStudy()
        let debugActions = StudyDetailDebugActionsView(study: study)
        XCTAssertTrue(debugActions.shouldShowDebugActions)
        let changed = expectation(description: "Locking publishes a study change")
        let subscription = study.objectWillChange.sink { changed.fulfill() }
        study.lockAdvancedSettings()
        XCTAssertFalse(debugActions.shouldShowDebugActions)
        await fulfillment(of: [changed], timeout: 1)
        subscription.cancel()
        try study.unlockAdvancedSettings(with: "000001")
        XCTAssertTrue(debugActions.shouldShowDebugActions)
    }

    private func makeStudy(
        identifier: String = "study",
        unlockCode: String? = "000001",
        isLockedByDefault: Bool = false
    ) -> Study {
        LockableStudy(
            unlockCode: unlockCode,
            isLockedByDefault: isLockedByDefault,
            studyIdentifier: identifier,
            sharedAppGroupIdentifier: suiteName
        )
    }
}

private final class LockableStudy: Study {
    private let unlockCode: String?
    private let isLockedByDefault: Bool

    init(unlockCode: String?, isLockedByDefault: Bool, studyIdentifier: String, sharedAppGroupIdentifier: String) {
        self.unlockCode = unlockCode
        self.isLockedByDefault = isLockedByDefault
        super.init(
            studyIdentifier: studyIdentifier,
            studyInformation: StudyInformation(title: "Test study", subtitle: "", contactEmail: "test@example.com", image: nil),
            uploadConfiguration: UploadConfiguration(serverURL: URL(string: "https://example.com")!, uploadFrequency: 3600, apiKey: "test"),
            introductorySurveyURL: nil,
            sharedAppGroupIdentifier: sharedAppGroupIdentifier,
            clientFactory: { _ in EmptyMockAPIClient() }
        )
    }

    override var advancedSettingsUnlockCode: String? { unlockCode }
    override var isAdvancedSettingsLockedByDefault: Bool { isLockedByDefault }
}
