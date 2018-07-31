//
//  SeparatorCellView.swift
//  TeamStatus
//
//  Created by Marcin Religa on 23/07/2018.
//  Copyright © 2018 Marcin Religa. All rights reserved.
//

import Cocoa

final class SeparatorCellView: NSTableCellView {
	@IBOutlet var titleLabel: NSTextField!
}

extension SeparatorCellView {
	struct ViewData {
		let title: String
	}

	func configure(with viewData: ViewData) {
		titleLabel.stringValue = viewData.title
	}
}
