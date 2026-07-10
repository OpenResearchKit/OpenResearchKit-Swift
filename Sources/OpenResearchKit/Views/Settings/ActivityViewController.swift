//
//  ActivityViewController.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 11.07.26.
//

import SwiftUI
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {

    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }

}
