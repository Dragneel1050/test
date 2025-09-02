//
//  CodeView.swift
//  Corbo
//
//  Created by Agustín Nanni on 5/9/23.
//

import Foundation
import SwiftUI

struct CodeView: View {
    @Binding var text: String
    @Binding var error: Bool
    
    @State private var text0 = ""
    @State private var text1 = ""
    @State private var text2 = ""
    @State private var text3 = ""
    @State private var err0 = false
    @State private var err1 = false
    @State private var err2 = false
    @State private var err3 = false
    @FocusState private var focus: Int?
    
    var body: some View {
        HStack{
            Spacer()
            DigitSquareTextField(id: 0, text: $text0, error: $err0, focus: _focus)
            DigitSquareTextField(id: 1, text: $text1, error: $err1, focus: _focus)
            DigitSquareTextField(id: 2, text: $text2, error: $err2, focus: _focus)
            DigitSquareTextField(id: 3, text: $text3, error: $err3, focus: _focus)
            Spacer()
        }.onChange(of: text0) { oldValue, newValue in
            handleFieldChange(index: 0, oldValue: oldValue, newValue: newValue)
        }.onChange(of: text1) { oldValue, newValue in
            handleFieldChange(index: 1, oldValue: oldValue, newValue: newValue)
        }.onChange(of: text2) {oldValue, newValue in
            handleFieldChange(index: 2, oldValue: oldValue, newValue: newValue)
        }.onChange(of: text3) { oldValue, newValue in
            handleFieldChange(index: 3, oldValue: oldValue, newValue: newValue)
        }.onChange(of: error, { _, new in
            if new {
                err0 = true
                err1 = true
                err2 = true
                err3 = true
            } else {
                err0 = false
                err1 = false
                err2 = false
                err3 = false
            }
        })
    }
    
    func handleFieldChange(index: Int, oldValue: String , newValue: String) {
        var value = newValue
        
        if value == "" {
            var textArray = Array(text)
            if (Array(text).indices.contains(index)) {
                textArray[index] = Character(" ")
            }
            text = String(textArray)
            
            switch index{
                case 0:
                    err0 = true
                case 1:
                    err1 = true
                    focus = 0
                case 2:
                    err2 = true
                    focus = 1
                case 3:
                    err3 = true
                    focus = 2
                default:
                    break
            }
            return
        }
        
        let decimals = CharacterSet.decimalDigits
        
        if value.count != 0 && value.count != 1 && value.count != 4 {
            value = String(value.first!)
        }
        
        switch index {
            case 0:
                if oldValue.count == 1 {
                    text0 = oldValue
                    focus = 1
                    return
                }
                
                let values = Array(value)
                if value.count == 4 {
                    text0 = String(values[0])
                    text1 = String(values[1])
                    text2 = String(values[2])
                    text3 = String(values[3])
                    text = value
                    return
                }
                
                text = value
                focus = 1
                text0 = value
                err0 = !CharacterSet(charactersIn: text0).isSubset(of: decimals)
                break;
            case 1:
                if oldValue.count == 1 {
                    text1 = oldValue
                    focus = 2
                    return
                }
                text += value
                focus = 2
                text1 = value
                err1 = !CharacterSet(charactersIn: text1).isSubset(of: decimals)
                break;
            case 2:
                if oldValue.count == 1 {
                    text2 = oldValue
                    focus = 3
                    return
                }
                text += value
                focus = 3
                text2 = value
                err2 = !CharacterSet(charactersIn: text2).isSubset(of: decimals)
                break;
            case 3:
                if oldValue.count == 1 {
                    text3 = oldValue
                    focus = nil
                    return
                }
                text += value
                focus = nil
                text3 = value
                err3 = !CharacterSet(charactersIn: text3).isSubset(of: decimals)
                break;
            default:
                if oldValue.count == 1 {
                    switch index {
                        case 0:
                            text0 = oldValue
                            break
                        case 1:
                            text1 = oldValue
                            break
                        case 2:
                            text2 = oldValue
                            break
                        case 3:
                            text3 = oldValue
                            break
                        default:
                            break
                    }
                }
        }
    }
    
    func retrieveIndexFromText(_ idx: Int) -> String {
        let values = Array(text)
        if values.indices.contains(idx) {
            return String(values[idx])
        } else {
            return ""
        }
    }
}

fileprivate struct DigitSquareTextField: View{
    let id: Int
    @Binding var text: String
    @Binding var error: Bool
    @FocusState var focus: Int?
    
    var body: some View {
        TextField("", text: $text)
            .font(Theme.formLabelSubtitle)
            .foregroundStyle(.textPrimary)
            .multilineTextAlignment(.center)
            .padding()
            .frame(width: 50, height: 50)
            .focused($focus, equals: id)
            .textContentType(.oneTimeCode)
            .keyboardType(.numberPad)
            .background{
                codeBackground(id: id, error: $error, focus: _focus)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                focus = id
            }
        
    }
}

fileprivate struct codeBackground: View {
    let id: Int
    @Binding var error: Bool
    @FocusState var focus: Int?

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .inset(by: 1)
            .fill(.surfaceFormControl)
            .stroke(focus == id ? .borderFormFocus : error ? .red : .borderForm )
    }
}

fileprivate struct CodeViewDefaultPreview: View{
    @State private var text = ""
    
    var body: some View{
        CodeView(text: $text, error: .constant(false))
    }
}

struct CodeView_Previews: PreviewProvider {
    static var previews: some View {
        CodeViewDefaultPreview()
    }
}
