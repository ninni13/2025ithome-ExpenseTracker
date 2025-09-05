//
//  CSVActivityItemSource.swift
//  ExpenseTracker
//
//  Created by Codex on 2025/9/6.
//

import UIKit
import UniformTypeIdentifiers
import LinkPresentation

/// An item source that tells the system this is a CSV file.
final class CSVActivityItemSource: NSObject, UIActivityItemSource {
    private let fileURL: URL
    private let filename: String
    
    init(fileURL: URL, filename: String? = nil) {
        self.fileURL = fileURL
        self.filename = filename ?? fileURL.lastPathComponent
        super.init()
    }
    
    // Placeholder must be lightweight and type-compatible with the real item
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return fileURL
    }
    
    // Provide the actual item for a specific activity (use the file URL)
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return fileURL
    }
    
    // Declare the UTI so activities (e.g., Files) treat it as CSV instead of generic text
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        if #available(iOS 14.0, *) {
            return UTType.commaSeparatedText.identifier
        } else {
            return "public.comma-separated-values-text"
        }
    }
    
    // Optional: set a subject/title used by some activities (e.g., Mail)
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return filename
    }
    
    // Optional: nicer metadata in the share sheet preview
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = filename
        return metadata
    }
}

