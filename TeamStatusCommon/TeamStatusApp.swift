//
//  TeamStatusApp.swift
//  TeamStatus
//
//  Created by Marcin Religa on 24/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

final class TeamStatusApp {
	private var viewModel: MainViewModel!
	fileprivate var semaphore: DispatchSemaphore?

	func run() {
		switch CommandLine.arguments.count {
		case 1:
			print("Error: Authorization token is required.")
		default:
			let token = CommandLine.arguments[1]
			viewModel = MainViewModel(view: self, token: token)
			semaphore = DispatchSemaphore(value: 0)
			viewModel.run()
			semaphore?.wait()
		}
	}

	fileprivate func finish() {
		semaphore?.signal()
	}
}

extension TeamStatusApp: MainViewProtocol {
	func didFinishRunning(reviewers: [Reviewer], pullRequests: [PullRequest]) {
		for reviewer in reviewers {
			let pullRequestsReviewRequested = reviewer.PRsToReview(in: pullRequests)
			let pullRequestsReviewed = reviewer.PRsReviewed(in: pullRequests)
			let login = reviewer.login.padding(toLength: 20, withPad: " ", startingAt: 0)
			print("\(login) requested in: \(pullRequestsReviewRequested.count), reviewed: \(pullRequestsReviewed.count)")
		}
		print("")

		finish()
	}

	func didFailToRun() {
		finish()
	}
}
