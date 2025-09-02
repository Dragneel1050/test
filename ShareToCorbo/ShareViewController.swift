//
//  ShareViewController.swift
//  ShareToCorbo
//
//  Created by Agustín Nanni on 29/05/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import UIKit
import Social
import SwiftUI
import Contacts

class ShareViewController: SLComposeServiceViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            if let attachments = item.attachments {
                for attachment: NSItemProvider in attachments {
                    if attachment.hasItemConformingToTypeIdentifier("public.vcard") {
                        processSharedVCard(attachment: attachment)
                    } else if attachment.hasItemConformingToTypeIdentifier("public.text") {
                        processSharedText(attachment: attachment)
                    }
                }
            }
        }
    }
    
    func processSharedVCard(attachment: NSItemProvider) {
        /*
         attachment.loadItem(forTypeIdentifier: "public.vcard", options: nil) {data, _ in
             do {
                 let vcardContacts = try CNContactVCardSerialization.contacts(with: data as! Data)
                 DispatchQueue.main.async {
                     self.addSubSwiftUIView(ExtensionAuthView{
                         SharedContactsView(candidateContacts: vcardContacts, close: self.close)
                     }, to: self.view)
                 }
             } catch {
                 (error)
             }
         }
         */
    }
    
    func processSharedText(attachment: NSItemProvider) {
        attachment.loadItem(forTypeIdentifier: "public.text", options: nil) {text, _ in
            DispatchQueue.main.async {
                self.addSubSwiftUIView(ExtensionAuthView{
                    StandaloneTextView(text: text as! String, doExit: {
                        self.close()
                    })
                }, to: self.view)
            }
        }
    }
    
    func close() {
        self.extensionContext?.completeRequest(returningItems: nil)
    }

}

extension UIViewController {
    
    func addSubSwiftUIView<Content>(_ swiftUIView: Content, to view: UIView) where Content : View {
        let hostingController = UIHostingController(rootView: swiftUIView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
          hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
          hostingController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
          view.bottomAnchor.constraint(equalTo: hostingController.view.bottomAnchor),
          view.rightAnchor.constraint(equalTo: hostingController.view.rightAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        hostingController.didMove(toParent: self)
    }
}
