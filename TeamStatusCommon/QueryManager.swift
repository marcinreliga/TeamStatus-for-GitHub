//
//  QueryManager.swift
//  TeamStatus
//
//  Created by Marcin Religa on 31/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

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

		return "{\"query\": \"query { rateLimit { cost limit remaining resetAt } viewer { login avatarUrl } repository(owner: \\\"\(teamName)\\\", name: \\\"\(repositoryName)\\\") { url  pullRequests(last: 30, states: OPEN) { edges { node { title author { login avatarUrl } updatedAt mergeable reviews(first: 100) { edges { node { author { login avatarUrl } } } }, reviewRequests(first: 100) { edges { node { requestedReviewer { ... on User { login avatarUrl } } } } } } } }  }}\" }"
	}

	var allPullRequestsQuery: String? {
		guard
			let repositoryName = repositoryName,
			let teamName = teamName
		else {
			return nil
		}

		return "{\"query\": \"query { rateLimit { cost limit remaining resetAt } viewer { login avatarUrl } repository(owner: \\\"\(teamName)\\\", name: \\\"\(repositoryName)\\\") { url  pullRequests(last: 100, states: [OPEN, MERGED]) { edges { node { title author { login avatarUrl } updatedAt mergeable reviews(first: 100) { edges { node { author { login avatarUrl } } } }, reviewRequests(first: 100) { edges { node { requestedReviewer { ... on User { login avatarUrl } } } } } } } }  }}\" }"
	}
}
