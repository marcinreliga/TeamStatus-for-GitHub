//
//  GraphAPIResponse.swift
//  TeamStatus
//
//  Created by Marcin Religa on 12/08/2018.
//  Copyright © 2018 Marcin Religa. All rights reserved.
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
		let author: Author
		let mergeable: String
		let reviewRequests: ReviewRequests
		let reviews: Reviews
	}
}

extension GraphAPIResponse.Data.Repository.PullRequests.Edge.Node {
	struct Author: Decodable {
		private enum CodingKeys: String, CodingKey {
			case login
			case avatarURL = "avatarUrl"
		}

		let login: String
		let avatarURL: URL
	}
}

extension GraphAPIResponse.Data.Repository.PullRequests.Edge.Node {
	struct ReviewRequests: Decodable {
		let edges: [Edge]
	}
}

extension GraphAPIResponse.Data.Repository.PullRequests.Edge.Node.ReviewRequests {
	struct Edge: Decodable {
		let node: Node
	}
}

extension GraphAPIResponse.Data.Repository.PullRequests.Edge.Node.ReviewRequests.Edge {
	struct Node: Decodable {
		let requestedReviewer: RequestedReviewer
	}
}

extension GraphAPIResponse.Data.Repository.PullRequests.Edge.Node {
	struct Reviews: Decodable {
		let edges: [Edge]
	}
}

extension GraphAPIResponse.Data.Repository.PullRequests.Edge.Node.Reviews {
	struct Edge: Decodable {
		let node: Node
	}
}

extension GraphAPIResponse.Data.Repository.PullRequests.Edge.Node.Reviews.Edge {
	struct Node: Decodable {
		let author: Author
	}
}

extension GraphAPIResponse.Data.Repository.PullRequests.Edge.Node.Reviews.Edge.Node {
	struct Author: Decodable {
		private enum CodingKeys: String, CodingKey {
			case login
			case avatarURL = "avatarUrl"
		}

		let login: String
		let avatarURL: URL
	}
}

extension GraphAPIResponse.Data.Repository.PullRequests.Edge.Node.ReviewRequests.Edge.Node {
	struct RequestedReviewer: Decodable {
		private enum CodingKeys: String, CodingKey {
			case login
			case avatarURL = "avatarUrl"
		}

		let login: String
		let avatarURL: URL
	}
}
