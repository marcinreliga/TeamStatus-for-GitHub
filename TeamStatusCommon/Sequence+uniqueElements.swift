//
//  Sequence.swift
//  TeamStatus
//
//  Created by Marcin Religa on 30/05/2017.
//  Copyright © 2017 Marcin Religa. All rights reserved.
//

import Foundation

extension Sequence where Iterator.Element: Hashable {
	var uniqueElements: [Iterator.Element] {
		return Array(Set(self))
	}
}
