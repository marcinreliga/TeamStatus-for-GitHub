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
		let query = "{\"query\": \"query { repository(owner: \\\"asosteam\\\", name: \\\"asos-native-ios\\\") {  pullRequests(last: 10, states: OPEN) { edges { node { id title updatedAt reviews(first: 5) { edges { node { id author { avatarUrl login resourcePath url } } } }, reviewRequests(first: 10) { edges { node { id reviewer { id name login } } } } } } }  }}\" }"

		if let url = URL(string: "https://api.github.com/graphql") {
			let networkManager = NetworkManager(remoteStorageURL: url)
			networkManager.query(query) { [weak self] result in
				switch result {
				case .success(let data):
					if let response = self?.parseResponse(data: data) {
						self?.parse(json: response)
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
//								if let id = node["id"] as? String {
//									print(id)
//								}
								if let title = node["title"] as? String {
									print(title)
								}

								if let reviewRequests = node["reviewRequests"] as? [String: Any] {
									if let edges = reviewRequests["edges"] as? [[String: Any]] {
										for edge in edges {
											if let node = edge["node"] as? [String: Any] {
//												if let id = node["id"] as? String {
//													print(id)
//												}
												if let reviewer = node["reviewer"] as? [String: Any] {
													if let login = reviewer["login"] as? String {
														print(login)
													}
													if let name = reviewer["name"] as? String {
														print(name)
													}
												}
											}
										}
									}
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
}
