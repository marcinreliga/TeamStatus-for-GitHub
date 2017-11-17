//
//  RequestedInCellView.swift
//  TeamStatus
//
//  Created by Marcin Religa on 18/06/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation
import Cocoa

final class RequestedInCellView: NSTableCellView {
	@IBOutlet private var levelIndicator: NSLevelIndicator!

	func configure(with viewData: ViewData) {
		levelIndicator.integerValue = viewData.integerValue
		levelIndicator.maxValue = viewData.maxValue
		levelIndicator.warningValue = viewData.warningValue
		levelIndicator.criticalValue = viewData.criticalValue
	}
}

extension RequestedInCellView {
	struct ViewData {
		let integerValue: Int
		let maxValue: Double
		let warningValue: Double
		let criticalValue: Double
	}
}
