//
//  PullRequest.swift
//  PRLoadBalancer
//
//  Created by Marcin Religa on 30/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

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
