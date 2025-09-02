//

import SwiftUI

struct ChatPanelBorder: Shape {
    let buttonBounds: CGRect
    let globalBounds: CGRect
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: buttonBounds.midX, y: buttonBounds.maxY))
        path.addCurve(to: CGPoint(x: buttonBounds.minX, y: buttonBounds.midY), control1:
                        CGPoint(x: buttonBounds.minX, y: buttonBounds.maxY - 2),
                      control2:
                        CGPoint(x: buttonBounds.minX, y: buttonBounds.midY))
        path.addCurve(to: CGPoint(x: buttonBounds.midX - 7, y: buttonBounds.minY + 1), control1:
                        CGPoint(x: buttonBounds.minX - 0.5, y: buttonBounds.midY + 2),
                      control2:
                        CGPoint(x: buttonBounds.minX - 2, y: buttonBounds.minY + 8))
        path.addLine(to: CGPoint(x: buttonBounds.minX + 20, y: buttonBounds.minY - 10))
        
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
        
        currentX = buttonBounds.maxX - 20
        
        path.addLine(to: CGPoint(x: currentX, y: navBarY))
        
        
        path.addLine(to: CGPoint(x: buttonBounds.maxX - 23.5, y: buttonBounds.minY + 1.3))
        
        path.addCurve(to: CGPoint(x: buttonBounds.maxX, y: buttonBounds.midY), control1:
                        CGPoint(x: buttonBounds.maxX + 1.5, y: buttonBounds.minY + 9),
                      control2:
                        CGPoint(x: buttonBounds.maxX, y: buttonBounds.midY))
        
        path.addCurve(to: CGPoint(x: buttonBounds.midX, y: buttonBounds.maxY), control1:
                        CGPoint(x: buttonBounds.maxX, y: buttonBounds.maxY),
                      control2:
                        CGPoint(x: buttonBounds.midX, y: buttonBounds.maxY))
        
        return path
    }
}
