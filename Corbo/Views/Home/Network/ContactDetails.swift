//
//  ContactDetails.swift
//  Corbo
//
//  Created by Agustín Nanni on 21/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct ContactDetails: View {
    let contactId: Int64
    
    @State private var data: contactDetailsDataViewProps? = nil
    
    var body: some View {
        VStack{
            header()
            if let props = data {
                contactDetailsDataView(props: props)
            } else {
                FullProgressView()
            }
        }
        .background{
            Background()
        }
        .task {
            if contactId != -1 {
                do {
                    let response = try await ApiModel.shared.contactDetails(contactId: contactId)
                    data = parseResponseData(response)
                } catch let err {
                    if case ApiErrors.RequestTimeout = err {
                        // Handle the timeout error
                        ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
                    } else {
                        ToastsModel.shared.notifyError(context: "ContactDetails.contactDetails", error: err )
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    func parseResponseData(_ data: contactDetailsResponse) -> contactDetailsDataViewProps {
        
        let email = {
            if let addresses = data.details?.emailAddresses {
                if !addresses.isEmpty {
                    let addr = addresses[0]
                    if let value = addr.value {
                        return value
                    }
                }
            }
            
            return ""
        }()
        
        let phone = {
            if let phones = data.details?.phoneNumbers {
                if !phones.isEmpty {
                    let phon = phones[0]
                    if let value = phon.value {
                        return value
                    }
                }
            }
            
            return ""
        }()
        
        return contactDetailsDataViewProps(
            contactId: data.contact?.id ?? -1,
            first: data.details?.firstName,
            last: data.details?.lastName, subtitle: data.details?.jobTitle, location: data.details?.organizationName, email: email, phone: phone, storyList: data.storyList ?? []
        )
    }
    
    @ViewBuilder
    func header() -> some View {
        ZStack{
            HStack{
                topNavButton(iconName: "Glyph=ChevronLeft") {
                    Task { @MainActor in
                        HomeModel.shared.homeNavPath.removeLast()
                    }
                }
                Spacer()
                /*
                topNavButton(iconName: "Glyph=ThreeDots") {
                    print("Hamburger")
                }
                */
            }
            HStack{
                Spacer()
                Text("CONTACT DETAILS")
                    .foregroundStyle(.textTitle)
                    .font(Theme.textTitle)
                Spacer()
            }
        }
        .padding()
    }
}

fileprivate struct contactDetailsDataView: View {
    let props: contactDetailsDataViewProps
    
    var body: some View {
        VStack{
            topPart()
            ContactDetailsBottom(props: props)
        }
    }
    
    @ViewBuilder
    func topPart() -> some View {
        VStack(spacing: 8){
            HStack{ Spacer() }
            ContactMonogram(firstName: props.first, lastName: props.last)
            Text(name())
                .font(Theme.contactName)
                .foregroundStyle(.textPrimary)
            if let subtitle = props.subtitle {
                Text(subtitle)
                    .font(Theme.contactSubtitle)
                    .foregroundStyle(.textHeader)
            }
            if let location = props.location {
                HStack(spacing: 2){
                    Image("Glyph=Location")
                        .foregroundStyle(.textPrimary)
                    Text(location)
                        .font(Theme.contactSubtitle)
                        .foregroundStyle(.textHeader)
                }
            }
        }
        .padding()
        .background{
            Color.surfacePanel
        }
    }
    
    func name() -> String {
        var name = ""
        if let first = props.first {
            name += first
        }
        if let last = props.last {
            if !name.isEmpty {
                name += " "
            }
            name += last
        }
        
        return name
    }
}

struct contactDetailsDataViewProps {
    let contactId: Int64
    let first: String?
    let last: String?
    let subtitle: String?
    let location: String?
    let email: String?
    let phone: String?
    let storyList: [storyWithEntities]
    
}

fileprivate struct ContactDetailsBottom: View {
    let props: contactDetailsDataViewProps

    enum selectedTab: CaseIterable{
        case contactInfo, suggestedStories
        
        var text: String {
            switch self {
            case .contactInfo:
                "Contact info"
            case .suggestedStories:
                "Mentioned in"
            }
        }
    }
    
    @State private var currentTab = selectedTab.contactInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20){
            ScrollView(.horizontal, showsIndicators: false){
                HStack(spacing: 25){
                    ForEach(selectedTab.allCases, id: \.self) { tab in
                        tabOption(tab)
                    }
                }
                .padding(.horizontal, 25)
            }
            
            ScrollView(.vertical) {
                Group{
                    switch currentTab {
                    case .contactInfo:
                        VStack{
                            FormTextField(placeholder: "First Name", text: .constant(props.first ?? ""))
                                .disabled(true)
                            FormTextField(placeholder: "Last Name", text: .constant(props.last ?? ""))
                                .disabled(true)
                            FormTextField(placeholder: "email@company.com", text: .constant(props.email ?? ""))
                                .disabled(true)
                            FormTextField(placeholder: "(123) 345-7890", text: .constant(props.phone ?? ""))
                                .disabled(true)
                        }
                    case .suggestedStories:
                        VStack{
                            ForEach(props.storyList, id: \.id) { story in
                                Button{
                                    HomeModel.shared.homeNavPath.append(story)
                                } label: {
                                    StoryCard(storyWithEntities: story)
                                }
                            }
                        }
                    }
                    
                }.padding(.horizontal)
            }
        }
    }
    
    func tabOption(_ tab: selectedTab) -> some View {
        let font = currentTab == tab ? Theme.questionsSelectionSelected : Theme.questionsSelectionSecondary
        let color = currentTab == tab ? Color.textPrimary : Color.textPrimary
        return Button{
            currentTab = tab
        } label: {
            Text(tab.text)
                .font(font)
                .foregroundStyle(color)
                .underline(currentTab == tab)
        }
    }
}

#Preview {
    ContactDetails(contactId: -1)
}


#Preview {
    GeometryReader { geo in
        contactDetailsDataView(props: contactDetailsDataViewProps(contactId: 1, first: "Pepe", last: "Argento", subtitle: "Shoe seller", location: "Austin, TX", email: "pepe.argento@gmail.com", phone: "+1 (123) 123 1234", storyList: [
            storyWithEntities(story: Story(id: 1, content: "Hello", userAccountId: 2, createdTime: Date.now, lastModifiedTime: Date.now), entityList: nil, location: Location(lat: 1, lon: 1, geocode: "Hallandale Beach, FL, US"))
        ]))
    }
    .background{
        Background()
    }
}
