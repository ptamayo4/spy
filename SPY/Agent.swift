//
//  Agent.swift
//  SPY
//
//  Created by Patrick Tamayo on 4/22/17.
//  Copyright © 2017 Patrick Tamayo. All rights reserved.
//

import Foundation

class Agent {
    var alias: String
    var team: String = "Blue"
    var score: Int = 0
    var active: Bool = false
    var inSession: Bool = false
    
    init(alias: String) {
        self.alias = alias
    }
}
