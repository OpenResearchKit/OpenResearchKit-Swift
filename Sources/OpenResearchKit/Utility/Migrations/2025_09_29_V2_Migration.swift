//
//  Migration-2025-09-29.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 29.09.25.
//

class AdaptNewDataFormatMigration: DataMigration {
    
    var id: String = "2025_09_29_V2_Migration"
    
    private let studyRegistry: StudyRegistry
    
    public init(studyRegistry: StudyRegistry = StudyRegistry.shared) {
        self.studyRegistry = studyRegistry
    }
    
    func perform() async throws {
        
        for study in studyRegistry.studies {
            self.updateStudy(study)
        }
        
    }
    
    private func updateStudy(_ study: Study) {
        
        // If a study got the consent, we also set that the participant has completed the introduction survey
        // as previously studies always had the consent in the introduction survey.
        if study.hasUserGivenConsent {
            study.completeIntroductionSurvey()
        }
        
        // If the termination survey was completed, we also set the new `isCompleted` property indicating that the study
        // was successfully completed. This property is the new umbrella property across studies as Data Donation studies
        // do not have termination surveys.
        if let study = study as? any HasTerminationSurvey {
            if study.hasCompletedTerminationSurvey {
                study.setCompleted()
            }
        }
        
        // If the study is a data donation study and there was consent given by the user, it is also clear
        // that the study was completed as completing the introduction survey / consent also meant completing the data donation.
        if let study = study as? DataDonationStudy, study.hasUserGivenConsent {
            study.setCompleted()
        }
        
        // We set the data donation studies to being dismissed as we didn't have a `isCompleted` flag before.
        if let study = study as? DataDonationStudy, study.isDismissedByUser {
            study.setCompleted()
        }
        
        
        
//        terminatedByUserDate
    }
    
}
