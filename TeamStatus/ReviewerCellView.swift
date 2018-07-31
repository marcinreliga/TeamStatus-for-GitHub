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
	@IBOutlet private var backgroundContainerView: NSView!
	@IBOutlet private var containerView: NSView!
	@IBOutlet private var imageContainerView: NSView!
	@IBOutlet private var loginLabel: NSTextField!
	@IBOutlet var pullRequestsReviewedLabel: NSTextField!
	@IBOutlet var levelIndicatorContainerView: NSView!
	@IBOutlet var levelIndicatorLevelView: NSView!
	@IBOutlet var levelIndicatorEmptyView: NSView!
	@IBOutlet var levelIndicatorLevelViewWidthConstraint: NSLayoutConstraint!
}

extension ReviewerCellView {
	struct ViewData {
		let login: String
		let levelIndicator: LevelIndicator
		let numberOfReviewedPRs: Int
		let totalNumberOfPRs: Int
		let avatarURL: URL?

		struct LevelIndicator {
			let integerValue: Int
			let maxValue: Double
		}
	}

	func configure(with viewData: ViewData) {
		loginLabel.stringValue = viewData.login
		containerView.wantsLayer = true
		containerView.layer?.backgroundColor = NSColor.white.cgColor

		levelIndicatorContainerView.isHidden = false
		levelIndicatorContainerView.wantsLayer = true

		levelIndicatorContainerView.layer?.backgroundColor = NSColor.lightGray.cgColor

		levelIndicatorLevelView.wantsLayer = true
		levelIndicatorLevelView.isHidden = false

		levelIndicatorLevelView.layer?.backgroundColor = NSColor(calibratedRed: 126/255.0, green: 200/255.0, blue: 107/255.0, alpha: 1).cgColor

		levelIndicatorEmptyView.wantsLayer = true
		levelIndicatorEmptyView.isHidden = false

		levelIndicatorEmptyView.layer?.backgroundColor = NSColor.gray.cgColor

		//	levelIndicatorContainerView.layer?.masksToBounds = true
		//	levelIndicatorContainerView.layer?.cornerRadius = 4

		let range = Double(levelIndicatorEmptyView.frame.width)
		let level = range * (Double(viewData.levelIndicator.integerValue) / viewData.levelIndicator.maxValue)

		levelIndicatorLevelViewWidthConstraint.constant = CGFloat(level)

		pullRequestsReviewedLabel.stringValue = "\(viewData.numberOfReviewedPRs) of \(viewData.totalNumberOfPRs)"
	}
}
