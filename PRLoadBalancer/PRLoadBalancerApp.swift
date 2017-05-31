//
//  PRLoadBalancerApp.swift
//  PRLoadBalancer
//
//  Created by Marcin Religa on 24/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

enum Configuration {
	static let apiBaseURL = URL(string: "https://api.github.com/graphql")!
}

final class PRLoadBalancerApp {
	private let queryManager: QueryManager = QueryManager()
	private let networkManager = NetworkManager(apiBaseURL: Configuration.apiBaseURL)

	private var reviewers: [Reviewer] = []

	func run() {
		let semaphore = DispatchSemaphore(value: 0)
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
						a.PRsToReview(in: pullRequests).count > b.PRsToReview(in: pullRequests).count
					})

					for reviewer in reviewersSorted {
						let pullRequestsReviewRequested = reviewer.PRsToReview(in: pullRequests)
						let pullRequestsReviewed = reviewer.PRsReviewed(in: pullRequests)

						print("\(reviewer.login), requested in: \(pullRequestsReviewRequested.count), reviewed: \(pullRequestsReviewed.count)")
					}

					print("")
				}
			case .failure:
				break
			}

			semaphore.signal()
		}
		semaphore.wait();
	}

	private func processPullRequest(pullRequest: PullRequest, for reviewer: Reviewer) {
		if reviewers.contains(where: { r in return r.login == reviewer.login }) == false {
			reviewers.append(reviewer)
		}
	}
}
