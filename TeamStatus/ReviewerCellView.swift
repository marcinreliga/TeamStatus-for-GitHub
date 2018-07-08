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
	@IBOutlet var pullRequestsReviewedLabel: NSTextField!
	@IBOutlet var levelIndicatorContainerView: NSView!
	@IBOutlet var levelIndicatorLevelView: NSView!
	@IBOutlet var levelIndicatorLevelViewWidthConstraint: NSLayoutConstraint!

	func configure(with viewData: ViewData) {
		loginLabel.stringValue = viewData.login
		containerView.wantsLayer = true
		containerView.layer?.backgroundColor = NSColor.white.cgColor

		if viewData.levelIndicator.integerValue == Int(viewData.levelIndicator.maxValue) {
			levelIndicatorContainerView.wantsLayer = false
			levelIndicatorContainerView.isHidden = true

			levelIndicatorLevelView.wantsLayer = false
			levelIndicatorLevelView.isHidden = true

//			levelIndicatorContainerView.layer?.masksToBounds = false
//			levelIndicatorContainerView.layer?.cornerRadius = 0
		} else {
			levelIndicatorContainerView.isHidden = false
			levelIndicatorContainerView.wantsLayer = true
			levelIndicatorContainerView.layer?.backgroundColor = NSColor.gray.cgColor //NSColor(calibratedRed: 234/255.0, green: 208/255.0, blue: 139/255.0, alpha: 1).cgColor

			levelIndicatorLevelView.wantsLayer = true
			levelIndicatorLevelView.isHidden = false

			levelIndicatorLevelView.layer?.backgroundColor = NSColor(calibratedRed: 126/255.0, green: 200/255.0, blue: 107/255.0, alpha: 1).cgColor

//			levelIndicatorContainerView.layer?.masksToBounds = true
//			levelIndicatorContainerView.layer?.cornerRadius = 4

			let level = 160 * (Double(viewData.levelIndicator.integerValue) / viewData.levelIndicator.maxValue)

			levelIndicatorLevelViewWidthConstraint.constant = CGFloat(level)
		}

//		levelIndicator.maxValue = viewData.levelIndicator.maxValue
//		levelIndicator.warningValue = viewData.levelIndicator.warningValue
//		levelIndicator.criticalValue = viewData.levelIndicator.criticalValue

		pullRequestsReviewedLabel.stringValue = "\(viewData.numberOfReviewedPRs) of \(viewData.totalNumberOfPRs)"
	}
}

extension ReviewerCellView {
	struct ViewData {
		let login: String
		let levelIndicator: LevelIndicator
		let numberOfReviewedPRs: Int
		let totalNumberOfPRs: Int

		struct LevelIndicator {
			let integerValue: Int
			let maxValue: Double
			let warningValue: Double
			let criticalValue: Double
		}
	}
}
