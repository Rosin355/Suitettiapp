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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .task { await store.load() }
        }
    }
}
