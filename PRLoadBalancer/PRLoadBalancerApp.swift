//
//  PRLoadBalancerApp.swift
//  PRLoadBalancer
//
//  Created by Marcin Religa on 24/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

final class PRLoadBalancerApp {
	private let responseParser: ResponseParser = ResponseParser()

	private var reviewers: [Reviewer] = []
	private var pullRequests: [PullRequest] = []

	func run() {
		let query = "{\"query\": \"query { repository(owner: \\\"asosteam\\\", name: \\\"asos-native-ios\\\") {  pullRequests(last: 100, states: OPEN) { edges { node { id title updatedAt reviews(first: 100) { edges { node { id author { avatarUrl login resourcePath url } } } }, reviewRequests(first: 10) { edges { node { id reviewer { id name login } } } } } } }  }}\" }"

		if let url = URL(string: "https://api.github.com/graphql") {
			let networkManager = NetworkManager(remoteStorageURL: url)
			networkManager.query(query) { [weak self] result in
				guard let _self = self else {
					return
				}

				switch result {
				case .success(let data):
					if let pullRequests = _self.responseParser.parseResponse(data: data) {
						_self.pullRequests = pullRequests

						let reviewersRequested = _self.pullRequests.flatMap({ $0.reviewersRequested })
						let reviewersReviewed = _self.pullRequests.flatMap({ $0.reviewersReviewed })

						_self.reviewers = (reviewersRequested + reviewersReviewed).uniqueElements

						let reviewersSorted = _self.reviewers.sorted(by: { a, b in
							a.PRsToReview(in: _self.pullRequests).count > b.PRsToReview(in: _self.pullRequests).count
						})

						for reviewer in reviewersSorted {
							let pullRequestsReviewRequested = reviewer.PRsToReview(in: _self.pullRequests)
							let pullRequestsReviewed = reviewer.PRsReviewed(in: _self.pullRequests)

							print("\(reviewer.login), requested in: \(pullRequestsReviewRequested.count), reviewed: \(pullRequestsReviewed.count)")
//							print("Requested in:")
//							for pr in pullRequestsReviewRequested {
//								print(pr.title)
//							}

//							print("Reviewed:")
//							for pr in pullRequestsReviewed {
//								print(pr.title)
//							}
//							print("\n")
						}

						print("")
					}
				case .failure:
					break
				}
			}
		}
	}

	private func processPullRequest(pullRequest: PullRequest, for reviewer: Reviewer) {
		if reviewers.contains(where: { r in return r.login == reviewer.login }) == false {
			reviewers.append(reviewer)
		}
	}
}
