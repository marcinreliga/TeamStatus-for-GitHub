//
//  PRLoadBalancerApp.swift
//  PRLoadBalancer
//
//  Created by Marcin Religa on 24/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

final class PRLoadBalancerApp {
	func run() {
		let query = "{\"query\": \"query { repository(owner: \\\"asosteam\\\", name: \\\"asos-native-ios\\\") {  pullRequests(last: 100, states: CLOSED) { edges { node { id title updatedAt reviews(first: 100) { edges { node { id author { avatarUrl login resourcePath url } } } }, reviewRequests(first: 10) { edges { node { id reviewer { id name login } } } } } } }  }}\" }"

		if let url = URL(string: "https://api.github.com/graphql") {
			let networkManager = NetworkManager(remoteStorageURL: url)
			networkManager.query(query) { [weak self] result in
				switch result {
				case .success(let data):
					if let response = self?.parseResponse(data: data) {
						guard let _self = self else {
							return
						}
						_self.parse(json: response)

						_self.reviewers = _self.pullRequests.flatMap({ $0.reviewersRequested })

						_self.reviewers = _self.reviewers.uniqueElements

						//var reviewersDict: [String: [PullRequest]] = [:]
						for reviewer in _self.reviewers {
							let pullRequestsReviewRequested = _self.pullRequests.filter({
								$0.reviewersRequested.contains(where: { $0.login == reviewer.login })
							})

							let pullRequestsReviewed = _self.pullRequests.filter({
								$0.reviewersReviewed.contains(where: { $0.login == reviewer.login })
							})

							//reviewersDict[reviewer.login] = pullRequestsReviewRequested

							print("\(reviewer.login), requested in: \(pullRequestsReviewRequested.count), reviewed: \(pullRequestsReviewed.count)")
							print("Requested in:")
							for pr in pullRequestsReviewRequested {
								print(pr.title)
							}

							print("Reviewed:")
							for pr in pullRequestsReviewed {
								print(pr.title)
							}
							print("\n")
						}

						print("")
					}
				case .failure:
					break
				}
			}
		}
	}

	private func parse(json: [String: Any]) {
		if let data = json["data"] as? [String: Any] {
			if let repository = data["repository"] as? [String: Any] {
				if let pullRequests = repository["pullRequests"] as? [String: Any] {
					if let edges = pullRequests["edges"] as? [[String: Any]] {
						for edge in edges {
							if let node = edge["node"] as? [String: Any] {
								if let id = node["id"] as? String, let title = node["title"] as? String {
									//print(id)
									var pullRequestData = PullRequest(id: id, title: title)

									if let reviewRequests = node["reviewRequests"] as? [String: Any] {
										if let edges = reviewRequests["edges"] as? [[String: Any]] {
											for edge in edges {
												if let node = edge["node"] as? [String: Any] {
	//												if let id = node["id"] as? String {
	//													print(id)
	//												}
													if let reviewer = node["reviewer"] as? [String: Any] {

														if let login = reviewer["login"] as? String {
															//print(login)

															//reviewers.append(Reviewer(login: login))
															//processPullRequest(pullRequest: pullRequestData, for: Reviewer(login: login))
															//pullRequestData

															pullRequestData.reviewersRequested.append(Reviewer(login: login))
														}
//														if let name = reviewer["name"] as? String {
//															print(name)
//														}
													}
												}
											}
										}
									}



									if let reviews = node["reviews"] as? [String: Any] {
										if let edges = reviews["edges"] as? [[String: Any]] {
											for edge in edges {
												if let node = edge["node"] as? [String: Any] {

													if let reviewer = node["author"] as? [String: Any] {
														if let login = reviewer["login"] as? String {
															//print(login)
															pullRequestData.reviewersReviewed.append(Reviewer(login: login))
														}
													}
												}
											}
										}
									}

									self.pullRequests.append(pullRequestData)

								}
							}
						}
					}
				}
			}
		}
	}

	private func parseResponse(data: Data) -> [String: Any]? {
		do {
			let json = try JSONSerialization.jsonObject(with: data, options: [])

			if let responseData = json as? [String: Any] {
				//print(responseData)
				return responseData
			}
		} catch {
			print("JSON parsing error")
		}

		return nil
	}

	private var reviewers: [Reviewer] = []
	private var pullRequests: [PullRequest] = []

	private func processPullRequest(pullRequest: PullRequest, for reviewer: Reviewer) {
		if reviewers.contains(where: { r in return r.login == reviewer.login }) == false {
			reviewers.append(reviewer)
		}
	}
}

struct Reviewer: Hashable, Equatable {
	let login: String
	//var PRIdToReview: [String]

	init(login: String) {
		self.login = login
		//self.PRIdToReview = []
	}

	var hashValue: Int {
		return login.hashValue
	}

	public static func ==(lhs: Reviewer, rhs: Reviewer) -> Bool {
		return lhs.login == rhs.login
	}
}

struct PullRequest {
	let id: String
	let title: String
	var reviewersRequested: [Reviewer]
	var reviewersReviewed: [Reviewer]

	init(id: String, title: String, reviewersRequested: [Reviewer] = [], reviewersReviewed: [Reviewer] = []) {
		self.id = id
		self.title = title
		self.reviewersRequested = reviewersRequested
		self.reviewersReviewed = reviewersReviewed
	}
}

extension Sequence where Iterator.Element: Hashable {
	var uniqueElements: [Iterator.Element] {
		return Array(Set(self))
	}
}
