//
//  StatusMenuController.swift
//  TeamStatus
//
//  Created by Marcin Religa on 31/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {
	@IBOutlet var statusMenu: NSMenu!
	@IBOutlet var reviewerView: ReviewerView!
	@IBOutlet var tableView: NSTableView!
	@IBOutlet var viewerImageView: NSImageView!
	@IBOutlet var viewerLogin: NSTextField!
	@IBOutlet var viewerStatus: NSTextField!

	fileprivate var viewModel: MainViewModel!

	let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

	// TODO: How to do it properly?
	var viewDidLoad = false

	fileprivate var reviewers: [Reviewer]?
	fileprivate var pullRequests: [PullRequest]?
	fileprivate var viewer: Viewer?

	override func awakeFromNib() {
		guard viewDidLoad == false else {
			return
		}

		updateStatusIcon()
		updateMainView()
		scheduleRefreshing()

		let token = CommandLine.arguments[1]
		viewModel = MainViewModel(view: self, token: token)
		viewModel.run()

		viewDidLoad = true
	}

	private func scheduleRefreshing() {
		let timer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(self.refresh), userInfo: nil, repeats: true)
		RunLoop.main.add(timer, forMode: .commonModes)
	}

	private func updateMainView() {
		if let reviewerMenuItem = self.statusMenu.item(withTitle: "Reviewer") {
			reviewerMenuItem.view = reviewerView
		}
	}

	private func updateStatusIcon() {
		let icon = NSImage(named: NSImage.Name(rawValue: "statusIcon"))
		icon?.isTemplate = true // best for dark mode
		statusItem.image = icon
		statusItem.menu = statusMenu
	}

	@objc private func refresh() {
		viewModel.run()
	}

	@IBAction func quitClicked(sender: NSMenuItem) {
		NSApplication.shared.terminate(self)
	}

	@IBAction func refreshClicked(sender: NSButton) {
		print("refresh")
		viewModel.run()
	}
}

extension StatusMenuController: MainViewProtocol {
	func didFinishRunning(reviewers: [Reviewer], pullRequests: [PullRequest], viewer: Viewer?) {
		self.reviewers = reviewers
		self.pullRequests = pullRequests
		self.viewer = viewer

		self.tableView.reloadData()
	}

	func didFailToRun() {
		Logger.log("Did fail to run")
	}

	func updateStatusItem(title: String, isAttentionNeeded: Bool) {
		let titleToSet: String
		if isAttentionNeeded {
			titleToSet = "\(title) ✋"
		} else {
			titleToSet = title
		}

		statusItem.title = titleToSet
	}

	func updateViewerView(with reviewer: Reviewer, pullRequestsToReviewCount: Int) {
		viewerLogin.stringValue = reviewer.login
		viewerStatus.stringValue = "requested in \(pullRequestsToReviewCount) pull request(s)"
		if let imageURL = reviewer.avatarURL {
			viewerImageView?.loadImageFromURL(urlString: imageURL.absoluteString)
		}
	}
}

extension StatusMenuController: NSTableViewDataSource {
	func numberOfRows(in tableView: NSTableView) -> Int {
		return reviewers?.count ?? 0
	}
}

extension StatusMenuController: NSTableViewDelegate {
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let tableColumn = tableColumn else {
			fatalError()
		}

		switch tableColumn.identifier {
		case NSUserInterfaceItemIdentifier("UserLoginTableColumn"):
			guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ReviewerCellView"), owner: self) as? ReviewerCellView else {
				fatalError()
			}

			let viewData = viewModel.viewDataForUserLoginCell(at: row)
			cell.configure(with: viewData)
			return cell
		case NSUserInterfaceItemIdentifier("RequestedInTableColumn"):
			guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RequestedInCellView"), owner: self) as? RequestedInCellView else {
				fatalError()
			}

			guard let reviewers = reviewers, let pullRequests = pullRequests else {
				return nil
			}

			let reviewer = reviewers[row]

			let prsToReview = reviewer.PRsToReview(in: pullRequests).count
			let prsReviewed = reviewer.PRsReviewed(in: pullRequests).count
			let totalPRs = prsToReview + prsReviewed
			cell.pullRequestsToReviewLabel.stringValue = ""
			cell.levelIndicator.integerValue = prsReviewed
			cell.levelIndicator.maxValue = Double(totalPRs)
			cell.levelIndicator.warningValue = 0.5 * Double(totalPRs)
			cell.levelIndicator.criticalValue = 0.25 * Double(totalPRs)
			return cell
		case NSUserInterfaceItemIdentifier("ReviewedTableColumn"):
			guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ReviewedCellView"), owner: self) as? ReviewedCellView else {
				fatalError()
			}

			let viewData = viewModel.viewDataForReviewedCell(at: row)
			cell.configure(with: viewData)
			return cell
		case NSUserInterfaceItemIdentifier("AvatarTableColumn"):
			guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AvatarCellView"), owner: self) as? AvatarCellView else {
				fatalError()
			}

			guard let reviewers = reviewers else {
				return nil
			}

			let reviewer = reviewers[row]

			if let imageURL = reviewer.avatarURL {
				cell.imageView?.loadImageFromURL(urlString: imageURL.absoluteString)
			}

			return cell
		default:
			fatalError()
		}
	}
}
