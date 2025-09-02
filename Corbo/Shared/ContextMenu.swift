//
//  ContextMenu.swift
//  Corbo
//
//  Created by Agustín Nanni on 18/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct ContextMenu: View {
    let options: [ContextMenuAction]
    let dismiss: () -> Void
    
    @State private var working = false
    
    var body: some View {
        VStack(spacing: 0){
            ForEach(Array(options.enumerated()), id: \.offset) { index, elem in
                ContextMenuRow(elem: elem, dismiss: dismiss, parentWorking: $working)
                if index != options.count - 1 {
                    Rectangle()
                        .fill(Color.borderPrimary)
                        .frame(height: 1)
                }
            }
        }
        .background{
            RoundedRectangle(cornerRadius: 10)
                .stroke(.borderPrimary, lineWidth: 1)
                .fill(Color.surfaceOverlayDark)
        }
        .frame(maxWidth: 180)
        .anchorPreference(key: ContextMenuBoundsPreferenceKey.self, value: .bounds, transform: { $0 })
    }
}

struct ContextMenuRow: View {
    let elem: ContextMenuAction
    let dismiss: () -> Void
    @Binding var parentWorking: Bool
    @State private var working = false

    var body: some View {
        switch elem {
        case is ButtonContextMenuAction:
            buttonContextMenuAction(buttonAction: elem as! ButtonContextMenuAction)
        case is ShareContextmenuAction:
            shareContextMenuAction(shareAction: elem as! ShareContextmenuAction)
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    func buttonContextMenuAction(buttonAction: ButtonContextMenuAction) -> some View {
        Button(action: {
            if parentWorking {
                return
            }
            Task {
                do {
                    parentWorking = true
                    working = true
                    try await  buttonAction.action()
                    dismiss()
                } catch let err {
                    
                    if case ApiErrors.RequestTimeout = err {
                        // Handle the timeout error
                        ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
                    } else {
                        await ToastsModel.shared.notifyError(context: "ContextMenuRow.buttonContextMenuAction()", error: err )
                    }
                }
                
                parentWorking = false
                working = false
            }
        }) {
            HStack{
                Text(buttonAction.label)
                    .font(.system(size: 16))
                    .foregroundStyle(.textPrimary)
                Spacer()
                ProgressView()
                    .tint(.textPrimary)
                    .opacity(working ? 1 : 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
    }
    
    @ViewBuilder
    func shareContextMenuAction(shareAction: ShareContextmenuAction) -> some View {
        ShareLink(item: shareAction.content + ConfigModel.buildSharedByText(), label: {
            HStack{
                Text("Share")
                    .font(.system(size: 16))
                    .foregroundStyle(.textPrimary)
                Spacer()
                ProgressView()
                    .tint(.textPrimary)
                    .opacity(working ? 1 : 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        })
    }
}

protocol ContextMenuAction {
}

struct ButtonContextMenuAction: ContextMenuAction {
    let label: String
    let action: () async throws -> Void
}

struct ShareContextmenuAction: ContextMenuAction {
    let content: String
}

struct ContextMenuBoundsPreferenceKey: PreferenceKey {
    typealias Value = Anchor<CGRect>?
    
    static var defaultValue: Value = nil
    
    static func reduce(
        value: inout Value,
        nextValue: () -> Value
    ) {
        value = nextValue()
    }
}


#Preview {
    GeometryReader{ _ in
        VStack{
            ContextMenu(options: [
                ButtonContextMenuAction(label: "Hello world!", action: {}),
                ButtonContextMenuAction(label: "Hello world!", action: {}),
                ButtonContextMenuAction(label: "Hello world!", action: {}),
                ShareContextmenuAction(content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse ex massa, varius et lectus quis, cursus porta leo. Vestibulum pretium iaculis metus, a congue ante dignissim id. Fusce non finibus ligula. Suspendisse et nulla vel velit aliquam auctor. Ut sollicitudin arcu vitae lorem tristique, eget viverra odio malesuada. Nam tempus sodales elit, ornare consequat lectus cursus a. Suspendisse potenti. Proin sapien purus, laoreet quis facilisis at, gravida vel magna. Nunc eget leo et nunc accumsan commodo. Ut quis dolor eu ex rutrum porttitor vitae ac nisl. Vestibulum a enim eget ante egestas placerat eget ac tellus. Aliquam erat volutpat. Mauris eu bibendum magna. Sed laoreet feugiat mi sed eleifend. Vivamus pulvinar urna id interdum maximus. Aliquam dapibus gravida urna, vel lobortis erat tincidunt non. In efficitur ipsum eget rhoncus interdum. Nam at nibh a ante molestie ultrices. Pellentesque eget lorem fringilla, laoreet nisi quis, gravida nunc. Sed in auctor neque, ac dapibus ligula. Ut maximus urna eget vestibulum ullamcorper. Etiam sed porttitor felis. Ut dolor nisl, tempus quis pulvinar sit amet, maximus non felis. Cras eget rhoncus eros. Phasellus a magna sit amet tortor cursus hendrerit at sed est. Donec dignissim nisi nec vehicula vestibulum. Etiam maximus odio non erat gravida ultrices.")
            ], dismiss: {print("dismiss")})
        }.padding()
    }
    .background(Background())
}
