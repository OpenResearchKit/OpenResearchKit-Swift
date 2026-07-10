//
//  StudyDataArchiveShareItem.swift
//  OpenResearchKit
//
//  Created by Lennart Fischer on 11.07.26.
//

import Foundation

struct StudyDataArchiveShareItem: Identifiable {

    let url: URL

    var id: URL {
        url
    }

}
