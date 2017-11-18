//
//  PullRequest.swift
//  TeamStatus
//
//  Created by Marcin Religa on 30/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

struct PullRequest {
	let id: String
	let title: String
	let authorLogin: String
	let mergeable: String
	var reviewersRequested: [Reviewer]
	var reviewersReviewed: [Reviewer]

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
