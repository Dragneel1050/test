//
//  Logs.swift
//  Corbo
//
//  Created by Agustín Nanni on 16/07/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation
import OSLog

class AppLogs {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let defaultLogger = Logger(subsystem: subsystem, category: "default")
}
