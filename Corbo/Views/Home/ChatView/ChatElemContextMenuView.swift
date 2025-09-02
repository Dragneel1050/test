//
//  ChatElemContextMenuView.swift
//  Corbo
//
//  Created by Agustín Nanni on 17/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct ChatElemContextMenuView: View {
    let dismiss: () -> Void
    let elem: ContextChatElement
    let options: [ContextMenuAction]
    
    @State private var targetHeightOffset: CGFloat = .zero
    @State private var bigMessage = false
    
    var body: some View {
        GeometryReader{ geo in
            VStack(alignment: .leading) {
                ChatBubble(text: elem.elem.text ?? "", variant: getVariant(elem.elem.type))
                    .frame(maxHeight: bigMessage ?  geo.size.height * 0.6 : nil)
                HStack{
                    Spacer()
                    ContextMenu(options: options, dismiss: dismiss)
                }
                .transition(.slide)
                .padding(.trailing)
                
            }
            .offset(y: targetHeightOffset)
            .onAppear{
                if !bigMessage{
                    targetHeightOffset = geo[elem.anchor].origin.y
                }
            }
            .onPreferenceChange(ContextMenuBoundsPreferenceKey.self, perform: {
                correctOffset($0, geo: geo)
            })
            .padding(.horizontal, 16)
        }
        .coordinateSpace(name: "home")
        .contentShape(Rectangle())
        .onTapGesture(perform: dismiss)
    }
    
    func getVariant(_ type: ChatElementType) -> ChatBubbleVariants {
        switch type {
        case .assistantMessage:
            return .assistant
        case .userTranscript:
            return .user
        case .storyList:
            return .assistant
        }
    }
    
    func correctOffset(_ anchor: Anchor<CGRect>?, geo: GeometryProxy) {
        guard let anchor = anchor else {
            return
        }
        
        let menuMaxY = geo[anchor].maxY
        let messageMinY = geo[elem.anchor].minY
        let screenHeight = geo.size.height
        let messageHeight = geo[elem.anchor].height
        
        if messageHeight > screenHeight * 0.6 {
            bigMessage = true
        }
                
        if menuMaxY > screenHeight {
            let delta = (menuMaxY - screenHeight) + 20
            targetHeightOffset -= delta
            return
        }
        
        if messageMinY < 50 {
            targetHeightOffset = messageMinY.magnitude
            return
        }
    }
}
