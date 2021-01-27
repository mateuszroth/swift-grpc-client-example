//
//  CounterTypeIds.swift
//  SwiftGRPC
//
//  Created by Mateusz Roth on 27/01/2021.
//

import Foundation
import SwiftProtobuf

enum CounterTypeIds: String {
    case counterBody = "sync.entities.CounterBody"
    case incrementCounter = "sync.entities.IncrementCounter"
    case decrementCounter = "sync.entities.DecrementCounter"
    case deleteCounter = "sync.entities.DeleteCounter"
}
