//
//  StatusMenuController.swift
//  PRLoadBalancer
//
//  Created by Marcin Religa on 31/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {
	@IBOutlet weak var statusMenu: NSMenu!
	@IBOutlet weak var reviewerView: ReviewerView!
	@IBOutlet weak var tableView: NSTableView!

	private var viewModel: MainViewModel!

	let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)

	override func awakeFromNib() {
		let token = CommandLine.arguments[1]
		viewModel = MainViewModel(view: self, token: token)
		viewModel.run()

		let icon = NSImage(named: "statusIcon")
		icon?.isTemplate = true // best for dark mode
		statusItem.image = icon
		statusItem.menu = statusMenu

		if let reviewerMenuItem = self.statusMenu.item(withTitle: "Reviewer") {
			reviewerMenuItem.view = reviewerView
		}
	}

	@IBAction func quitClicked(sender: NSMenuItem) {
		NSApplication.shared().terminate(self)
	}

	fileprivate var reviewers: [Reviewer]?
	fileprivate var pullRequests: [PullRequest]?
}

extension StatusMenuController: MainViewProtocol {
	func didFinishRunning(reviewers: [Reviewer], pullRequests: [PullRequest]) {

		self.reviewers = reviewers
		self.pullRequests = pullRequests

		DispatchQueue.main.async {
			self.tableView.reloadData()
		}
	}

	func didFailToRun() {

	}
}

extension StatusMenuController: NSTableViewDataSource {
//	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
//		if let reviewers = reviewers {
//			let reviewer = reviewers[row]
//			return reviewer.login
//		} else {
//			return nil
//		}
//	}

	func numberOfRows(in tableView: NSTableView) -> Int {
		return 5
		//return reviewers?.count ?? 0
	}
}

extension StatusMenuController: NSTableViewDelegate {
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let cell = tableView.make(withIdentifier: "ReviewerCell", owner: self) as? NSTableCellView
		cell?.textField?.stringValue = "test"
		return cell
	}

//	func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
//		return nil
//	}
}
