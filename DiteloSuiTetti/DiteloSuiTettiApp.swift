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
    @State private var eventStore = EventStore()
    @State private var documentStore = DocumentStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(eventStore)
                .environment(documentStore)
                .task {
                    async let articles: () = store.load()
                    async let events: () = eventStore.load()
                    _ = await (articles, events)
                }
        }
    }
}
