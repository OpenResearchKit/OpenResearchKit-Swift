//
//  StudyDetailDebugActionsView.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 11.07.26.
//

import SwiftUI

public struct StudyDetailDebugActionsView: View {

    @ObservedObject private var study: Study

    @State private var isUploading = false
    @State private var alert: StudyDetailAlert?

    public init(study: Study) {
        self.study = study
    }

    public var body: some View {
        if shouldShowDebugActions {
            Section(header: Text("Research Data", bundle: .module)) {
                if study.shouldShowStudyDataExportAction() {
                    Button {
                        exportStudyData()
                    } label: {
                        Label("Export Study Data", systemImage: "square.and.arrow.up")
                    }
                }

                if study.shouldShowStudyDataForceUploadAction() {
                    Button {
                        forceUploadStudyData()
                    } label: {
                        Label("Force Upload", systemImage: "arrow.up.doc")
                    }
                    .disabled(isUploading)

                    if isUploading {
                        ProgressView()
                    }
                }
            }
            .alert(item: $alert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .cancel(Text("OK"))
                )
            }
        }
    }

    // MARK: - Actions
    
    private func exportStudyData() {
        do {
            let archiveURL = try study.studyFileManager.studyDataArchiveForSharing(
                study: study,
                date: Date()
            )
            StudyDetailSharePresenter.present(activityItems: [archiveURL])
        } catch {
            showAlert(
                title: "Export Failed",
                message: error.localizedDescription
            )
        }
    }

    private func forceUploadStudyData() {
        guard !isUploading else {
            return
        }

        isUploading = true

        Task { @MainActor in
            defer {
                isUploading = false
            }

            do {
                try study.copyMainJSONToUpload(date: Date())
                try await study.studyFileManager.uploadStudyFolder(study: study)

                showAlert(
                    title: "Upload Complete",
                    message: "Pending study data files were uploaded."
                )
            } catch {
                showAlert(
                    title: "Upload Failed",
                    message: error.localizedDescription
                )
            }
        }
    }

    private func showAlert(title: String, message: String) {
        alert = StudyDetailAlert(title: title, message: message)
    }
    
    // MARK: - Getter
    
    private var shouldShowDebugActions: Bool {
        return study.shouldShowStudyDataExportAction() || study.shouldShowStudyDataForceUploadAction()
    }
    
}
