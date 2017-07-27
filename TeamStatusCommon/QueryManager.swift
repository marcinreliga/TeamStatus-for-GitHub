//
//  QueryManager.swift
//  TeamStatus
//
//  Created by Marcin Religa on 31/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

struct Viewer {
	let login: String
}

struct APIResponse {
	var viewer: Viewer?
	var pullRequests: [PullRequest]

	init() {
		viewer = nil
		pullRequests = []
	}
}

final class QueryManager {
	let query = "{\"query\": \"query { rateLimit { cost limit remaining resetAt } viewer { login } repository(owner: \\\"asosteam\\\", name: \\\"asos-native-ios\\\") {  pullRequests(last: 30, states: OPEN) { edges { node { id title updatedAt reviews(first: 100) { edges { node { id author { avatarUrl login resourcePath url } } } }, reviewRequests(first: 100) { edges { node { id reviewer { avatarUrl name login } } } } } } }  }}\" }"
	
	func parseResponse(data: Data) -> APIResponse? {
		do {
			let json = try JSONSerialization.jsonObject(with: data, options: [])

			if let responseData = json as? [String: Any] {
				return parse(json: responseData)
			}
		} catch {
			print("JSON parsing error")
		}

		return nil
	}

	private func parse(json: [String: Any]) -> APIResponse {
		var apiResponse = APIResponse()

		if let data = json["data"] as? [String: Any] {
			if let viewer = data["viewer"] as? [String: String] {
				if let login = viewer["login"] {
					apiResponse.viewer = Viewer(login: login)
				}
			}
			if let repository = data["repository"] as? [String: Any] {
				if let pullRequests = repository["pullRequests"] as? [String: Any] {
					if let edges = pullRequests["edges"] as? [[String: Any]] {
						for edge in edges {
							if let node = edge["node"] as? [String: Any] {
								if let id = node["id"] as? String, let title = node["title"] as? String {
									var pullRequestData = PullRequest(id: id, title: title)

									if let reviewRequests = node["reviewRequests"] as? [String: Any] {
										if let edges = reviewRequests["edges"] as? [[String: Any]] {
											for edge in edges {
												if let node = edge["node"] as? [String: Any] {
													if let reviewer = node["reviewer"] as? [String: Any] {
														if let login = reviewer["login"] as? String {
															let avatarURLString: String?
															if let avatarURLStringParsed = reviewer["avatarUrl"] as? String {
																avatarURLString = avatarURLStringParsed
															} else {
																avatarURLString = nil
															}
															pullRequestData.reviewersRequested.append(Reviewer(login: login, avatarURLString: avatarURLString))
														}
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
															let avatarURLString: String?
															if let avatarURLStringParsed = reviewer["avatarUrl"] as? String {
																avatarURLString = avatarURLStringParsed
															} else {
																avatarURLString = nil
															}
															pullRequestData.reviewersReviewed.append(Reviewer(login: login, avatarURLString: avatarURLString))
														}
													}
												}
											}
										}
									}
									
									apiResponse.pullRequests.append(pullRequestData)
								}
							}
						}
					}
				}
			}
		}

		return apiResponse
	}
}
