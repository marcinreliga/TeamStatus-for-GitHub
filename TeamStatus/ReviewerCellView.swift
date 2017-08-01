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
	@IBOutlet var loginLabel: NSTextField!

	func configure(with viewData: ViewData) {
		loginLabel.stringValue = viewData.login
	}

	struct ViewData {
		let login: String
	}
}
