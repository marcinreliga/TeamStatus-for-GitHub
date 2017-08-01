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
	@IBOutlet var pullRequestsToReviewLabel: NSTextField!
	@IBOutlet var levelIndicator: NSLevelIndicator!
}
