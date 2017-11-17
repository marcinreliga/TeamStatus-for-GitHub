//
//  MainViewModel.swift
//  TeamStatus
//
//  Created by Marcin Religa on 31/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

protocol MainViewProtocol {
	func didFinishRunning(reviewers: [Reviewer], pullRequests: [PullRequest], viewer: Viewer?)
	func didFailToRun()
	func updateStatusItem(title: String, isAttentionNeeded: Bool)
	func updateViewerView(with reviewer: Reviewer, ownPullRequestsCount: Int, pullRequestsToReviewCount: Int, pullRequestsReviewed: Int)
}

final class MainViewModel {
	private let view: MainViewProtocol
	private let queryManager: QueryManager = QueryManager()
	private let networkManager: NetworkManager

	private var reviewersSorted: [Reviewer] = []
	private var pullRequests: [PullRequest] = []
	private var viewer: Viewer?
	private var repositoryURL: URL

	//private var reviewers: [Reviewer] = []

	init(view: MainViewProtocol, repositoryURL: URL, token: String) {
		self.view = view
		self.repositoryURL = repositoryURL
		self.networkManager = NetworkManager(apiBaseURL: Configuration.apiBaseURL, token: token)
	}

	func run() {
		guard let query = queryManager.query else {
			return Logger.log("Query is empty.")
		}

		networkManager.query(query) { [weak self] result in
			guard let _self = self else {
				return
			}
			switch result {
			case .success(let data):
				if let apiResponse = _self.queryManager.parseResponse(data: data) {
					let reviewersRequested = apiResponse.pullRequests.flatMap({ $0.reviewersRequested })
					let reviewersReviewed = apiResponse.pullRequests.flatMap({ $0.reviewersReviewed })
					let reviewers = (reviewersRequested + reviewersReviewed).uniqueElements

					let openPullRequests = apiResponse.pullRequests.filter({ $0.state == "OPEN" })

					_self.reviewersSorted = reviewers.sorted(by: { a, b in
						a.PRsToReview(in: openPullRequests).count < b.PRsToReview(in: openPullRequests).count
					})

					_self.pullRequests = openPullRequests

					_self.viewer = apiResponse.viewer

					if let viewer = _self.viewer {
						if let reviewer = _self.currentUserAsReviewer(viewer: viewer, in: reviewers) {
							let pullRequestsCount = _self.pullRequestsToReviewCount(for: reviewer, in: openPullRequests)
							let isAttentionNeeded = _self.hasAnyConflicts(for: viewer, in: openPullRequests)
							let ownPullRequestsCount = _self.numberOfPullRequests(for: viewer, in: openPullRequests)
							let pullRequestsReviewedCount = _self.numberOfPullRequestsReviewed(by: viewer, in: openPullRequests)

							DispatchQueue.main.async {
								// TODO: This can be merged into single call.
								_self.view.updateStatusItem(title: "\(pullRequestsCount)", isAttentionNeeded: isAttentionNeeded)
								_self.view.updateViewerView(
									with: reviewer,
									ownPullRequestsCount: ownPullRequestsCount,
									pullRequestsToReviewCount: pullRequestsCount,
									pullRequestsReviewed: pullRequestsReviewedCount
								)
							}
						}
					}

					DispatchQueue.main.async {
						_self.view.didFinishRunning(reviewers: _self.reviewersSorted, pullRequests: openPullRequests, viewer: apiResponse.viewer)
					}
				}
			case .failure:
				DispatchQueue.main.async {
					_self.view.didFailToRun()
				}
			}
		}
	}

	func currentUserAsReviewer(viewer: Viewer, in reviewers: [Reviewer]) -> Reviewer? {
		return reviewers.first(where: { $0.login == viewer.login})
	}

	func pullRequestsToReviewCount(for reviewer: Reviewer, in pullRequests: [PullRequest]) -> Int {
		return reviewer.PRsToReview(in: pullRequests).count
	}

	func hasAnyConflicts(for viewer: Viewer, in pullRequests: [PullRequest]) -> Bool {
		return pullRequests.first(where: { $0.mergeable == "CONFLICTING" && $0.authorLogin == viewer.login }) != nil
	}

	func numberOfPullRequests(for viewer: Viewer, in pullRequests: [PullRequest]) -> Int {
		return pullRequests.filter({ $0.authorLogin == viewer.login }).count
	}

	func numberOfPullRequestsReviewed(by viewer: Viewer, in pullRequests: [PullRequest]) -> Int {
		return pullRequests.filter({ $0.reviewersReviewed.contains(where: { $0.login == viewer.login }) }).count
	}

	// FIXME: Should not use UIKit subclasses.
	func viewDataForUserLoginCell(at rowIndex: Int) -> ReviewerCellView.ViewData {
		let reviewer = reviewersSorted[rowIndex]
		return .init(login: reviewer.login)
	}

	func viewDataForReviewedCell(at rowIndex: Int) -> ReviewedCellView.ViewData {
		let reviewer = reviewersSorted[rowIndex]

		let prsToReview = reviewer.PRsToReview(in: pullRequests).count
		let prsReviewed = reviewer.PRsReviewed(in: pullRequests).count
		let totalPRs = prsToReview + prsReviewed

		return .init(pullRequestsReviewedText: "\(prsReviewed) of \(totalPRs)")
	}

	func openMyPullRequests() {
		guard
			let viewer = viewer,
			let url = URL(string: "\(repositoryURL.absoluteString)/pulls?q=is%3Apr+is%3Aopen+sort%3Aupdated-desc+author%3A\(viewer.login)")
		else {
			return
		}

		openBrowser(with: url)
	}

	func openAwaitingReviewPullRequests() {
		guard
			let viewer = viewer,
			let url = URL(string: "\(repositoryURL.absoluteString)/pulls?q=is%3Apr+is%3Aopen+sort%3Aupdated-desc+review-requested%3A\(viewer.login)")
		else {
			return
		}

		openBrowser(with: url)
	}

	func openReviewedPullRequests() {
		guard
			let viewer = viewer,
			let url = URL(string: "\(repositoryURL.absoluteString)/pulls?q=is%3Apr+is%3Aopen+sort%3Aupdated-desc+reviewed-by%3A\(viewer.login)")
		else {
			return
		}

		openBrowser(with: url)
	}

	func openAllPullRequests() {
		openMyPullRequests()
		openAwaitingReviewPullRequests()
		openReviewedPullRequests()
	}

	private func openBrowser(with url: URL) {
		Process.launchedProcess(launchPath: "/usr/bin/open", arguments: [url.absoluteString])
	}
}
