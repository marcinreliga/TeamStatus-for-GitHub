//
//  ReviewerView.swift
//  TeamStatus
//
//  Created by Marcin Religa on 31/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Cocoa

class ReviewerView: NSView {
	@IBOutlet weak var reviewerLabel: NSTextField!

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

//		self.wantsLayer = true
//		self.layer?.backgroundColor = NSColor.red.cgColor
	}
}
