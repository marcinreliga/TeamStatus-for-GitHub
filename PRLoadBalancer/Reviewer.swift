//
//  Reviewer.swift
//  PRLoadBalancer
//
//  Created by Marcin Religa on 30/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

struct Reviewer: Hashable, Equatable {
	let login: String
	let avatarURL: URL?

	init(login: String, avatarURL: URL? = nil) {
		self.login = login
		self.avatarURL = avatarURL
	}

	init(login: String, avatarURLString: String? = nil) {
		self.login = login
		if let avatarURLString = avatarURLString {
			self.avatarURL = URL(string: avatarURLString)
		} else {
			self.avatarURL = nil
		}
	}

	var hashValue: Int {
		return login.hashValue
	}

	public static func ==(lhs: Reviewer, rhs: Reviewer) -> Bool {
		return lhs.login == rhs.login
	}
}

extension Reviewer {
	func PRsToReview(in pullRequests: [PullRequest]) -> [PullRequest] {
		return pullRequests.filter({
			$0.reviewersRequested.contains(where: { $0.login == login })
		})
	}

	func PRsReviewed(in pullRequests: [PullRequest]) -> [PullRequest] {
		return pullRequests.filter({
			$0.reviewersReviewed.contains(where: { $0.login == login })
		})
	}
}
