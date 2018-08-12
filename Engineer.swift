//
//  Engineer.swift
//  TeamStatus
//
//  Created by Marcin Religa on 12/08/2018.
//  Copyright © 2018 Marcin Religa. All rights reserved.
//

import Foundation

struct Engineer: Decodable, Hashable {
	let login: String
	let avatarURL: URL
}

extension Engineer {
	init(viewer: GraphAPIResponse.Data.Viewer) {
		self.login = viewer.login
		self.avatarURL = viewer.avatarURL
	}
}

extension Engineer {
	init(author: GraphAPIResponse.Data.Repository.PullRequests.Edge.Node.Author) {
		self.login = author.login
		self.avatarURL = author.avatarURL
	}
}

extension Engineer {
	init(author: GraphAPIResponse.Data.Repository.PullRequests.Edge.Node.Reviews.Edge.Node.Author) {
		self.login = author.login
		self.avatarURL = author.avatarURL
	}
}

extension Engineer {
	init(requestedReviewer: GraphAPIResponse.Data.Repository.PullRequests.Edge.Node.ReviewRequests.Edge.Node.RequestedReviewer) {
		self.login = requestedReviewer.login
		self.avatarURL = requestedReviewer.avatarURL
	}
}

extension Engineer {
	func PRsToReview(in pullRequests: [GraphAPIResponse.Data.Repository.PullRequests.Edge.Node]) -> [GraphAPIResponse.Data.Repository.PullRequests.Edge.Node] {
		return pullRequests.filter({
			$0.reviewRequests.edges.contains(where: { $0.node.requestedReviewer.login == login })
		})
	}

	func PRsReviewed(in pullRequests: [GraphAPIResponse.Data.Repository.PullRequests.Edge.Node]) -> [GraphAPIResponse.Data.Repository.PullRequests.Edge.Node] {
		return pullRequests.filter({
			$0.reviews.edges.contains(where: { $0.node.author.login == login })
		})
	}
}
