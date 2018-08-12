//
//  Reviewer.swift
//  TeamStatus
//
//  Created by Marcin Religa on 30/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

//struct Reviewer: Hashable, Equatable, Decodable {
//	let login: String
//	let avatarURL: URL
//
//	var hashValue: Int {
//		return login.hashValue
//	}
//
//	public static func ==(lhs: Reviewer, rhs: Reviewer) -> Bool {
//		return lhs.login == rhs.login
//	}
//}

extension Reviewer {
	init(viewer: GraphAPIResponse.Data.Viewer) {
		self.login = viewer.login
		self.avatarURL = viewer.avatarURL
	}
}

extension Engineer {
	func PRsToReview(in pullRequests: [GraphAPIResponse.Data.Repository.PullRequest]) -> [GraphAPIResponse.Data.Repository.PullRequest] {
		return pullRequests.filter({
			$0.reviewersRequested.contains(where: { $0.login == login })
		})
	}

	func PRsReviewed(in pullRequests: [GraphAPIResponse.Data.Repository.PullRequest]) -> [GraphAPIResponse.Data.Repository.PullRequest] {
		return pullRequests.filter({
			$0.reviewersReviewed.contains(where: { $0.login == login })
		})
	}
}
