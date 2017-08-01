//
//  MainViewModel.swift
//  TeamStatus
//
//  Created by Marcin Religa on 31/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

protocol MainViewProtocol {
	func didFinishRunning(reviewers: [Reviewer], pullRequests: [PullRequest], viewer: Viewer?)
	func didFailToRun()
	func updateStatusItem(title: String)
	func updateViewerView(with reviewer: Reviewer, pullRequestsToReviewCount: Int)
}

final class MainViewModel {
	private let view: MainViewProtocol
	private let queryManager: QueryManager = QueryManager()
	private let networkManager: NetworkManager

	//private var reviewers: [Reviewer] = []

	init(view: MainViewProtocol, token: String) {
		self.view = view
		self.networkManager = NetworkManager(apiBaseURL: Configuration.apiBaseURL, token: token)
	}

	func run() {
		networkManager.query(queryManager.query) { [weak self] result in
			guard let _self = self else {
				return
			}
			switch result {
			case .success(let data):
				if let apiResponse = _self.queryManager.parseResponse(data: data) {
					let reviewersRequested = apiResponse.pullRequests.flatMap({ $0.reviewersRequested })
					let reviewersReviewed = apiResponse.pullRequests.flatMap({ $0.reviewersReviewed })

					let reviewers = (reviewersRequested + reviewersReviewed).uniqueElements

					let reviewersSorted = reviewers.sorted(by: { a, b in
						a.PRsToReview(in: apiResponse.pullRequests).count < b.PRsToReview(in: apiResponse.pullRequests).count
					})

					if let viewer = apiResponse.viewer {
						if let reviewer = _self.currentUserAsReviewer(viewer: viewer, in: reviewers) {
							let pullRequestsCount = _self.pullRequestsToReviewCount(for: reviewer, in: apiResponse.pullRequests)
							_self.view.updateStatusItem(title: "\(pullRequestsCount)")
							_self.view.updateViewerView(with: reviewer, pullRequestsToReviewCount: pullRequestsCount)
						}
					}

					_self.view.didFinishRunning(reviewers: reviewersSorted, pullRequests: apiResponse.pullRequests, viewer: apiResponse.viewer)
				}
			case .failure:
				_self.view.didFailToRun()
			}
		}
	}

	func currentUserAsReviewer(viewer: Viewer, in reviewers: [Reviewer]) -> Reviewer? {
		return reviewers.first(where: { $0.login == viewer.login})
	}

	func pullRequestsToReviewCount(for reviewer: Reviewer, in pullRequests: [PullRequest]) -> Int {
		return reviewer.PRsToReview(in: pullRequests).count
	}
}
