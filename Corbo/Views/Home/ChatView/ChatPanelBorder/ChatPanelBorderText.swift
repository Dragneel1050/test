//
//  ChatPanelBorderText.swift
//  Corbo
//
//  Created by Agustín Nanni on 28/05/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct ChatPanelBorderText: Shape {
    let globalBounds: CGRect
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: globalBounds.midX, y: globalBounds.maxY - 30))
        
        var currentX = globalBounds.minX + 40
        var currentY = path.currentPoint?.y ?? .zero
        let navBarY = currentY
        
        path.addLine(to: CGPoint(x: currentX, y: currentY))
        
        currentX = currentX - 30
        currentY = currentY - 30
        path.addQuadCurve(to: CGPoint(x: currentX, y: currentY),
                          control: CGPoint(x: currentX, y: currentY + 30))
        
        currentY = globalBounds.minY + 30
        path.addLine(to: CGPoint(x: currentX, y: currentY))
        
        currentX = currentX + 30
        currentY = currentY - 30
        path.addQuadCurve(to: CGPoint(x: currentX, y: currentY),
                          control: CGPoint(x: currentX - 30, y: currentY))
        
        currentX = globalBounds.maxX - 40
        path.addLine(to: CGPoint(x: currentX, y: currentY))
        
        currentX = currentX + 30
        currentY = currentY + 30
        path.addQuadCurve(to: CGPoint(x: currentX, y: currentY),
                          control: CGPoint(x: currentX, y: currentY - 30))
        
        currentY = navBarY - 30
        path.addLine(to: CGPoint(x: currentX, y: currentY))
        
        currentX = currentX - 30
        currentY = currentY + 30
        path.addQuadCurve(to: CGPoint(x: currentX, y: currentY),
                          control: CGPoint(x: currentX + 30, y: currentY))
        
        
        path.addLine(to: CGPoint(x: currentX, y: navBarY))
        
        
        path.addLine(to: CGPoint(x: globalBounds.midX, y: globalBounds.maxY - 30))
        
        return path
    }
}
