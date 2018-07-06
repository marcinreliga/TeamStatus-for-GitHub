//
//  ReviewerCellView.swift
//  TeamStatus
//
//  Created by Marcin Religa on 02/06/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation
import Cocoa

final class ReviewerCellView: NSTableCellView {
	@IBOutlet private var containerView: NSView!
	@IBOutlet private var loginLabel: NSTextField!
	@IBOutlet private var levelIndicator: NSLevelIndicator!
	@IBOutlet var pullRequestsReviewedLabel: NSTextField!

	func configure(with viewData: ViewData) {
		loginLabel.stringValue = viewData.login
		containerView.wantsLayer = true
		containerView.layer?.backgroundColor = NSColor.white.cgColor

		levelIndicator.integerValue = viewData.levelIndicator.integerValue
		levelIndicator.maxValue = viewData.levelIndicator.maxValue
		levelIndicator.warningValue = viewData.levelIndicator.warningValue
		levelIndicator.criticalValue = viewData.levelIndicator.criticalValue

		pullRequestsReviewedLabel.stringValue = viewData.pullRequestsReviewedText
	}
}

extension ReviewerCellView {
	struct ViewData {
		let login: String
		let levelIndicator: LevelIndicator
		let pullRequestsReviewedText: String

		struct LevelIndicator {
			let integerValue: Int
			let maxValue: Double
			let warningValue: Double
			let criticalValue: Double
		}
	}
}
