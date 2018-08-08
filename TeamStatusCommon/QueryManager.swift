//
//  QueryManager.swift
//  TeamStatus
//
//  Created by Marcin Religa on 31/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

struct GraphAPIResponse: Decodable {
	let data: Data
}

extension GraphAPIResponse {
	struct Data: Decodable {
		let viewer: Viewer
		let repository: Repository
	}
}

extension GraphAPIResponse.Data {
	struct Viewer: Decodable {
		private enum CodingKeys: String, CodingKey {
			case login
			case avatarURL = "avatarUrl"
		}

		let login: String
		let avatarURL: URL
	}

	struct Repository: Decodable {
		//let url: URL
		let pullRequests: PullRequests
	}
}

extension GraphAPIResponse.Data.Repository {
	struct PullRequests: Decodable {
		let edges: [Edge]
	}
}

extension GraphAPIResponse.Data.Repository.PullRequests {
	struct Edge: Decodable {
		let node: Node
	}
}

extension GraphAPIResponse.Data.Repository.PullRequests.Edge {
	struct Node: Decodable {
		let title: String
	}
}

extension GraphAPIResponse.Data.Repository {
	struct PullRequest: Decodable {
		private enum CodingKeys: String, CodingKey {
			case id
			case title
			case authorLogin
			case mergeable
			case reviewersRequested
			case reviewersReviewed
		}

		let id: String
		let title: String
		let authorLogin: String
		let mergeable: String
		var reviewersRequested: [Reviewer]
		var reviewersReviewed: [Reviewer]

		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let id: String = try container.decode(String.self, forKey: .id)
			let title: String = try container.decode(String.self, forKey: .title)
			let authorLogin: String = try container.decode(String.self, forKey: .authorLogin)
			let mergeable: String = try container.decode(String.self, forKey: .mergeable)

			self.init(id: id, title: title, authorLogin: authorLogin, mergeable: mergeable, reviewersRequested: [], reviewersReviewed: [])
		}

		init(
			id: String,
			title: String,
			authorLogin: String,
			mergeable: String,
			reviewersRequested: [Reviewer] = [],
			reviewersReviewed: [Reviewer] = []
		) {
			self.id = id
			self.title = title
			self.authorLogin = authorLogin
			self.mergeable = mergeable
			self.reviewersRequested = reviewersRequested
			self.reviewersReviewed = reviewersReviewed
		}
	}
}

struct APIResponse {
	var viewer: GraphAPIResponse.Data.Viewer?
	var repositoryURL: URL?
	var pullRequests: [GraphAPIResponse.Data.Repository.PullRequest] = []
}

final class QueryManager {
	private var repositoryPathComponents: [String]? {
		guard
			let input = CommandLineInput(),
			let path = URLComponents(url: input.repositoryURL, resolvingAgainstBaseURL: false)?.path
		else {
			return nil
		}

		return path.split(separator: "/").map({ String($0) })
	}

	private var repositoryName: String? {
		guard
			let pathComponents = repositoryPathComponents,
			let repositoryName = pathComponents.last
		else {
			return nil
		}

		return String(repositoryName)
	}

	private var teamName: String? {
		guard
			let pathComponents = repositoryPathComponents,
			let teamName = pathComponents.first
		else {
			return nil
		}

		return String(teamName)
	}

	var openPullRequestsQuery: String? {
		guard
			let repositoryName = repositoryName,
			let teamName = teamName
		else {
			return nil
		}

		return "{\"query\": \"query { rateLimit { cost limit remaining resetAt } viewer { login avatarUrl } repository(owner: \\\"\(teamName)\\\", name: \\\"\(repositoryName)\\\") { url  pullRequests(last: 30, states: OPEN) { edges { node { id title author { login avatarUrl } updatedAt mergeable reviews(first: 100) { edges { node { id author { login avatarUrl } } } }, reviewRequests(first: 100) { edges { node { id requestedReviewer { ... on User { name login avatarUrl } } } } } } } }  }}\" }"
	}

	var allPullRequestsQuery: String? {
		guard
			let repositoryName = repositoryName,
			let teamName = teamName
		else {
			return nil
		}

		return "{\"query\": \"query { rateLimit { cost limit remaining resetAt } viewer { login avatarUrl } repository(owner: \\\"\(teamName)\\\", name: \\\"\(repositoryName)\\\") { url  pullRequests(last: 100, states: [OPEN, MERGED]) { edges { node { id title author { login avatarUrl } updatedAt mergeable reviews(first: 100) { edges { node { id author { login avatarUrl } } } }, reviewRequests(first: 100) { edges { node { id requestedReviewer { ... on User { name login avatarUrl } } } } } } } }  }}\" }"
	}
	
	func parseResponse(data: Data) -> APIResponse? {

		do {
			let graphAPIResponse = try JSONDecoder().decode(GraphAPIResponse.self, from: data)

			print("parsed")

//			if let responseData = json as? [String: Any] {
//				return parse(json: responseData)
//			}
		} catch {
			print("JSON parsing error: \(error)")
		}

		print("decoded")

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

		guard let data = json["data"] as? [String: Any] else {
			return apiResponse
		}

		if let viewer = data["viewer"] as? [String: String] {
			apiResponse.viewer = parseViewer(from: viewer)
		}

		if let repository = data["repository"] as? [String: Any] {
			if let url = repository["url"] as? String {
				apiResponse.repositoryURL = URL(string: url)
			}
			if let pullRequests = repository["pullRequests"] as? [String: Any] {
				apiResponse.pullRequests = parsePullRequests(from: pullRequests)
			}
		}

		return apiResponse
	}

	private func parsePullRequests(from input: [String: Any]) -> [GraphAPIResponse.Data.Repository.PullRequest] {
		guard let edges = input["edges"] as? [[String: Any]] else {
			return []
		}

		return edges.compactMap({
			guard let node = $0["node"] as? [String: Any] else {
				return nil
			}

			guard
				let id = node["id"] as? String,
				let title = node["title"] as? String,
				let mergeable = node["mergeable"] as? String,
				let author = node["author"] as? [String: Any],
				let authorLogin = author["login"] as? String
			else {
				return nil
			}

			var pullRequestData = GraphAPIResponse.Data.Repository.PullRequest(
				id: id,
				title: title,
				authorLogin: authorLogin,
				mergeable: mergeable
			)

			if let reviewRequests = node["reviewRequests"] as? [String: Any] {
				pullRequestData.reviewersRequested = parseReviewers(from: reviewRequests, reviewerKey: "requestedReviewer")
			}

			if let reviews = node["reviews"] as? [String: Any] {
				pullRequestData.reviewersReviewed = parseReviewers(from: reviews, reviewerKey: "author")
			}

			return pullRequestData
		})
	}

	private func parseReviewers(from input: [String: Any], reviewerKey: String) -> [Reviewer] {
		guard let edges = input["edges"] as? [[String: Any]] else {
			return []
		}

		return edges.compactMap({
			guard
				let node = $0["node"] as? [String: Any],
				let reviewer = node[reviewerKey] as? [String: Any],
				let login = reviewer["login"] as? String,
				let avatarURLString = reviewer["avatarUrl"] as? String,
				let avatarURL = URL(string: avatarURLString)
			else {
				return nil
			}

			return Reviewer(login: login, avatarURL: avatarURL)
		})
	}

	private func parseViewer(from input: [String: String]) -> GraphAPIResponse.Data.Viewer? {
		guard
			let login = input["login"],
			let avatarURLString = input["avatarUrl"],
			let avatarURL = URL(string: avatarURLString)
		else {
			return nil
		}

		return GraphAPIResponse.Data.Viewer(login: login, avatarURL: avatarURL)
	}
}
