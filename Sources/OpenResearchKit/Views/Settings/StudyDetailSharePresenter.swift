//
//  StudyDetailSharePresenter.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 26.07.26.
//

import UIKit

enum StudyDetailSharePresenter {

    static func present(activityItems: [Any]) {
        guard let sourceViewController = UIViewController.topViewController() else {
            return
        }

        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = sourceViewController.view
            popoverPresentationController.sourceRect = sourceViewController.view.bounds
        }

        sourceViewController.present(activityViewController, animated: true)
    }

}
