//
//  NikahApp.swift
//  Nikah
//
//  Created by Nahian Zarif on 9/3/26.
//

import SwiftUI
import Firebase
import FirebaseFirestore

@main
struct NikahApp: App {
    @StateObject private var authVM: AuthViewModel

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        _authVM = StateObject(wrappedValue: AuthViewModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
        }
    }
}
