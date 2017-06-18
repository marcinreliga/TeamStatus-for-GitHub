//
//  StatusMenuController.swift
//  PRLoadBalancer
//
//  Created by Marcin Religa on 31/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {
	@IBOutlet var statusMenu: NSMenu!
	@IBOutlet var reviewerView: ReviewerView!
	@IBOutlet var tableView: NSTableView!

	private var viewModel: MainViewModel!

	let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)

	// TODO: How to do it properly?
	var viewDidLoad = false

	override func awakeFromNib() {
		if viewDidLoad == false {
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

			let timer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(self.refresh), userInfo: nil, repeats: true)
			RunLoop.main.add(timer, forMode: .commonModes)

			viewDidLoad = true
		}
	}

	func refresh() {
		print("auto refresh")
		viewModel.run()
	}

	@IBAction func quitClicked(sender: NSMenuItem) {
		NSApplication.shared().terminate(self)
	}

	@IBAction func refreshClicked(sender: NSButton) {
		print("refresh")
		viewModel.run()
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
		case "UserLoginTableColumn":
			guard let cell = tableView.make(withIdentifier: "ReviewerCellView", owner: self) as? ReviewerCellView else {
				fatalError()
			}

			guard let reviewers = reviewers else {
				return nil
			}

			let reviewer = reviewers[row]

			cell.loginLabel.stringValue = reviewer.login
			return cell
		case "RequestedInTableColumn":
			guard let cell = tableView.make(withIdentifier: "RequestedInCellView", owner: self) as? RequestedInCellView else {
				fatalError()
			}

			guard let reviewers = reviewers, let pullRequests = pullRequests else {
				return nil
			}

			let reviewer = reviewers[row]

			cell.pullRequestsToReviewLabel.stringValue = "\(reviewer.PRsToReview(in: pullRequests).count)"
			return cell
		case "ReviewedTableColumn":
			guard let cell = tableView.make(withIdentifier: "ReviewedCellView", owner: self) as? ReviewedCellView else {
				fatalError()
			}

			guard let reviewers = reviewers, let pullRequests = pullRequests else {
				return nil
			}

			let reviewer = reviewers[row]

			cell.pullRequestsReviewedLabel.stringValue = "\(reviewer.PRsReviewed(in: pullRequests).count)"
			return cell
		case "AvatarTableColumn":
			guard let cell = tableView.make(withIdentifier: "AvatarCellView", owner: self) as? AvatarCellView else {
				fatalError()
			}

			guard let reviewers = reviewers else {
				return nil
			}

			let reviewer = reviewers[row]

			if let imageURL = reviewer.avatarURL {
				//let image = NSImage(byReferencing: imageURL)
				cell.imageView?.imageFromServerURL(urlString: imageURL.absoluteString)
			}

			return cell
		default:
			fatalError()
		}

	}

//	func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
//		return nil
//	}
}

extension NSImageView {
	public func imageFromServerURL(urlString: String) {

		URLSession.shared.dataTask(with: NSURL(string: urlString)! as URL, completionHandler: { (data, response, error) -> Void in

			if error != nil {
				//print(error)
				return
			}
			DispatchQueue.main.async(execute: { () -> Void in
				let image = NSImage(data: data!)
				self.image = image
			})

		}).resume()
	}
}

