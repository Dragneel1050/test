//
//  NetworkMonitor.swift
//  Corbo
//
//  Created by Agustín Nanni on 03/09/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation
import Network
import Combine

enum NetworkStatus {
    case connected, disconnected
}

class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private let nwPathMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "Monitor")
    let statusPublisher = PassthroughSubject<NetworkStatus, Never>()

    init() {
        nwPathMonitor.pathUpdateHandler = { path in
            Task{
                await MainActor.run{
                    if path.status == .satisfied {
                        self.statusPublisher.send(.connected)
                    } else {
                        self.statusPublisher.send(.disconnected)
                    }
                }
            }
        }
        
        nwPathMonitor.start(queue: workerQueue)
    }
}
