//
//  Preview indicator.swift
//  Corbo
//
//  Created by Agustín Nanni on 18/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI
import TipKit

struct PreviewIndicator: View {
    var body: some View {
        Label("Feature preview", systemImage: "info.circle")
            .font(.caption2)
            .foregroundStyle(.textPrimary)
            .help("Help")
            .opacity(0.6)
    }
}

struct Preview_indicatorTip : Tip {
    var title: Text {
        Text("Feature preview")
    }


    var message: Text? {
        Text("This is a representation of a possible future feature and may change over time.")
    }


    var image: Image? {
        Image(systemName: "info.circle")
    }
}

#Preview {
    PreviewIndicator()
}
