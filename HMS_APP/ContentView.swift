//
//  ContentView.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 30/04/25.
//

import SwiftUI
import FirebaseCore

struct ContentView: View {
    @State private var showingTestDashboard = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square.fill")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            
            Text("Hospital Management System")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Welcome to the HMS app")
                .foregroundColor(.secondary)
            
            Spacer().frame(height: 40)
            
            Button(action: {
                showingTestDashboard = true
            }) {
                HStack {
                    Image(systemName: "hammer.fill")
                    Text("Open Service Test Dashboard")
                }
                .padding()
                .frame(maxWidth: 280)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .sheet(isPresented: $showingTestDashboard) {
            TestDashboardView()
        }
        .onAppear {
            // Set up Firebase
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
        }
    }
}

#Preview {
    ContentView()
}
