//
//  MainViewModel.swift
//  TeamStatus
//
//  Created by Marcin Religa on 31/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

protocol MainViewProtocol {
	func didFinishRunning(reviewers: [Reviewer], pullRequests: [PullRequest])
	func didFailToRun()
}

final class MainViewModel {
	private let view: MainViewProtocol
	private let queryManager: QueryManager = QueryManager()
	private let networkManager: NetworkManager

	private var reviewers: [Reviewer] = []

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
				if let pullRequests = _self.queryManager.parseResponse(data: data) {
					let reviewersRequested = pullRequests.flatMap({ $0.reviewersRequested })
					let reviewersReviewed = pullRequests.flatMap({ $0.reviewersReviewed })

					_self.reviewers = (reviewersRequested + reviewersReviewed).uniqueElements

					let reviewersSorted = _self.reviewers.sorted(by: { a, b in
						a.PRsToReview(in: pullRequests).count < b.PRsToReview(in: pullRequests).count
					})

					_self.view.didFinishRunning(reviewers: reviewersSorted, pullRequests: pullRequests)
				}
			case .failure:
				_self.view.didFailToRun()
			}
		}
	}
}
