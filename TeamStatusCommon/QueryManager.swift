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
	var repositoryURL: URL?
	var pullRequests: [PullRequest] = []
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

		return "{\"query\": \"query { rateLimit { cost limit remaining resetAt } viewer { login } repository(owner: \\\"\(teamName)\\\", name: \\\"\(repositoryName)\\\") { url  pullRequests(last: 30, states: OPEN) { edges { node { id title author { login } updatedAt mergeable reviews(first: 100) { edges { node { id author { avatarUrl login resourcePath url } } } }, reviewRequests(first: 100) { edges { node { id requestedReviewer { ... on User { avatarUrl name login } } } } } } } }  }}\" }"
	}

	var allPullRequestsQuery: String? {
		guard
			let repositoryName = repositoryName,
			let teamName = teamName
		else {
			return nil
		}

		return "{\"query\": \"query { rateLimit { cost limit remaining resetAt } viewer { login } repository(owner: \\\"\(teamName)\\\", name: \\\"\(repositoryName)\\\") { url  pullRequests(last: 100, states: [OPEN, MERGED]) { edges { node { id title author { login } updatedAt mergeable reviews(first: 100) { edges { node { id author { avatarUrl login resourcePath url } } } }, reviewRequests(first: 100) { edges { node { id requestedReviewer { ... on User { avatarUrl name login } } } } } } } }  }}\" }"
	}
	
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

	private func parsePullRequests(from input: [String: Any]) -> [PullRequest] {
		guard let edges = input["edges"] as? [[String: Any]] else {
			return []
		}

		return edges.flatMap({
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

			var pullRequestData = PullRequest(
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

		return edges.flatMap({
			guard
				let node = $0["node"] as? [String: Any],
				let reviewer = node[reviewerKey] as? [String: Any],
				let login = reviewer["login"] as? String
			else {
				return nil
			}

			let avatarURLString = parseAvatar(from: reviewer)
			return Reviewer(login: login, avatarURLString: avatarURLString)
		})
	}

	private func parseViewer(from input: [String: String]) -> Viewer? {
		guard let login = input["login"] else {
			return nil
		}

		return Viewer(login: login)
	}

	private func parseAvatar(from input: [String: Any]) -> String? {
		guard let avatarURLString = input["avatarUrl"] as? String else {
			return nil
		}

		return avatarURLString
	}
}
