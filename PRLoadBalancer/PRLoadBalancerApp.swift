//
//  PRLoadBalancerApp.swift
//  PRLoadBalancer
//
//  Created by Marcin Religa on 24/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

final class PRLoadBalancerApp {
	private var viewModel: MainViewModel!
	fileprivate var semaphore: DispatchSemaphore?

	func run() {
		viewModel = MainViewModel(view: self)
		semaphore = DispatchSemaphore(value: 0)
		viewModel.run()
		semaphore?.wait()
	}

	fileprivate func finish() {
		semaphore?.signal()
	}
}

extension PRLoadBalancerApp: MainViewProtocol {
	func didFinishRunning(reviewers: [Reviewer], pullRequests: [PullRequest]) {
		for reviewer in reviewers {
			let pullRequestsReviewRequested = reviewer.PRsToReview(in: pullRequests)
			let pullRequestsReviewed = reviewer.PRsReviewed(in: pullRequests)

			print("\(reviewer.login), requested in: \(pullRequestsReviewRequested.count), reviewed: \(pullRequestsReviewed.count)")
		}
		print("")

		finish()
	}

	func didFailToRun() {
		finish()
	}
}
