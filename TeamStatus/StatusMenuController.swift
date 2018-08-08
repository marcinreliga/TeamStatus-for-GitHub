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
	@IBOutlet var myPullRequestsButton: NSButton!
	@IBOutlet var awaitingReviewButton: NSButton!
	@IBOutlet var reviewedButton: NSButton!

	fileprivate var viewModel: MainViewModel!

	let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

	// TODO: How to do it properly?
	var viewDidLoad = false

	fileprivate var viewer: GraphAPIResponse.Data.Viewer?

	override func awakeFromNib() {
		guard viewDidLoad == false else {
			return
		}

		updateStatusIcon()
		updateMainView()

		guard let input = CommandLineInput() else {
			return
		}

		scheduleRefreshing()

		viewModel = MainViewModel(view: self, repositoryURL: input.repositoryURL, token: input.token)
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

	@IBAction func openMyPullRequestsClicked(sender: NSButton) {
		viewModel.openMyPullRequests()
		statusMenu.cancelTracking()
	}

	@IBAction func openAwaitingReviewPullRequestsClicked(sender: NSButton) {
		viewModel.openAwaitingReviewPullRequests()
		statusMenu.cancelTracking()
	}

	@IBAction func openReviewedPullRequestsClicked(sender: NSButton) {
		viewModel.openReviewedPullRequests()
		statusMenu.cancelTracking()
	}

	@IBAction func openAllPullRequestsClicked(sender: NSButton) {
		viewModel.openAllPullRequests()
		statusMenu.cancelTracking()
	}
}

extension StatusMenuController: MainViewProtocol {
	func didFinishRunning(reviewers: [Reviewer], pullRequests: [GraphAPIResponse.Data.Repository.PullRequest], viewer: GraphAPIResponse.Data.Viewer?) {
		self.viewer = viewer

		self.tableView.reloadData()
	}

	func didFailToRun() {
		Logger.log("Did fail to run")
	}

	func updateStatusItem(title: String, isAttentionNeeded: Bool) {
		let titleToSet: String
		if isAttentionNeeded {
			titleToSet = "\(title) ⚠️"
		} else {
			titleToSet = title
		}

		statusItem.title = titleToSet
	}

	func updateViewerView(with reviewer: Reviewer, ownPullRequestsCount: Int, pullRequestsToReviewCount: Int, pullRequestsReviewed: Int) {
		viewerLogin.stringValue = reviewer.login
		viewerImageView?.loadImageFromURL(urlString: reviewer.avatarURL.absoluteString)

		myPullRequestsButton.title = "my (\(ownPullRequestsCount))"
		awaitingReviewButton.title = "awaiting (\(pullRequestsToReviewCount))"
		reviewedButton.title = "reviewed (\(pullRequestsReviewed))"
	}
}

extension StatusMenuController: NSTableViewDataSource {
	func numberOfRows(in tableView: NSTableView) -> Int {
		// Because of separators.
		// TODO: define sections (row types) properly.
		return viewModel.reviewersSorted.count + 2
	}
}

extension StatusMenuController: NSTableViewDelegate {
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let tableColumn = tableColumn else {
			fatalError()
		}

		switch tableColumn.identifier {
		case NSUserInterfaceItemIdentifier("UserLoginTableColumn"):
			guard viewModel.isSeparator(at: row) == false else {
				guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: String(describing: SeparatorCellView.self)), owner: self) as? SeparatorCellView else {
					fatalError()
				}

				let viewData = viewModel.viewDataForSeparator(at: row)
				cell.configure(with: viewData)
				return cell
			}

			guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: String(describing: ReviewerCellView.self)), owner: self) as? ReviewerCellView else {
				fatalError()
			}

			let viewData = viewModel.viewDataForUserLoginCell(at: row)
			cell.configure(with: viewData)

			if let imageURL = viewData.avatarURL {
				cell.imageView?.loadImageFromURL(urlString: imageURL.absoluteString)
			}
			return cell
		default:
			fatalError()
		}
	}
}
