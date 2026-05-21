//
//  DiteloSuiTettiApp.swift
//  DiteloSuiTetti
//
//  Created by Romesh Singhabahu on 19/05/26.
//

import SwiftUI

@main
struct DiteloSuiTettiApp: App {
    @State private var store = ArticleStore()
    @State private var documentStore = DocumentStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(documentStore)
                .task { await store.load() }
        }
    }
}
