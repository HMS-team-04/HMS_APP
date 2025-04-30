//
//  AuthManager.swift
//  MediCareManager
//
//  Created by s1834 on 18/04/25.
//

import Foundation
import FirebaseFirestore

struct UserInfo {
    let id: String
    let name: String
    let email: String
    let role: String?
    let accessLevel: Admin.AccessLevel?
    let gender: String?
    let number: Int?
    
    // Initialize from Admin model
    init(from admin: Admin) {
        self.id = admin.id
        self.name = admin.name
        self.email = admin.email
        self.role = admin.role
        self.accessLevel = admin.accessLevel
        self.gender = admin.gender
        self.number = admin.number
    }
    
    // Default initialization
    init(id: String, name: String, email: String, role: String? = nil, accessLevel: Admin.AccessLevel? = .readonly, gender: String? = nil, number: Int? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.accessLevel = accessLevel
        self.gender = gender
        self.number = number
    }
}

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool
    @Published var currentUserID: String
    @Published var currentUser: UserInfo?
    private let firestoreService = AdminFirestoreService.shared
    
    init() {
        // Check if user is logged in from UserDefaults
        if let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty {
            self.isLoggedIn = true
            self.currentUserID = userId
            // Try to load user info
            self.currentUser = loadUserInfoFromDefaults()
            
            // Try to fetch the latest user info from Firestore
            Task {
                await fetchUserFromFirestore()
            }
        } else {
            self.isLoggedIn = false
            self.currentUserID = ""
            self.currentUser = nil
        }
    }
    
    // Login functionality
    func login(userId: String, userName: String = "", userEmail: String = "") {
        isLoggedIn = true
        currentUserID = userId
        UserDefaults.standard.set(userId, forKey: "userId")
        
        // Try to load existing user data
        currentUser = loadUserInfoFromDefaults()
        
        // If we have name/email from the login process, use those
        if !userName.isEmpty || !userEmail.isEmpty {
            let name = userName.isEmpty ? (currentUser?.name ?? "") : userName
            let email = userEmail.isEmpty ? (currentUser?.email ?? "") : userEmail
            let role = currentUser?.role
            let accessLevel = currentUser?.accessLevel ?? .readonly
            
            currentUser = UserInfo(id: userId, name: name, email: email, role: role, accessLevel: accessLevel)
            saveUserInfoToDefaults()
        }
        
        // Fetch latest data from Firestore
        Task {
            await fetchUserFromFirestore()
        }
    }
    
    // Logout functionality
    func logout() {
        isLoggedIn = false
        currentUserID = ""
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userRole")
        UserDefaults.standard.removeObject(forKey: "userAccessLevel")
        UserDefaults.standard.removeObject(forKey: "userGender")
        UserDefaults.standard.removeObject(forKey: "userNumber")
    }
    
    // Update user info
    func updateUserInfo(name: String, email: String = "", role: String? = nil, accessLevel: Admin.AccessLevel? = nil) {
        // Update local state
        let newAccessLevel = accessLevel ?? currentUser?.accessLevel ?? .readonly
        let newRole = role ?? currentUser?.role
        let gender = currentUser?.gender
        let number = currentUser?.number
        
        currentUser = UserInfo(
            id: currentUserID,
            name: name,
            email: email.isEmpty ? (currentUser?.email ?? "") : email,
            role: newRole,
            accessLevel: newAccessLevel,
            gender: gender,
            number: number
        )
        saveUserInfoToDefaults()
        
        // Update Firestore
        Task {
            // Try to get existing admin first
            if var existingAdmin = try? await firestoreService.getAdmin(userId: currentUserID) {
                // Only update fields that have changed
                var updatedFields: [String: Any] = [:]
                
                if !name.isEmpty && name != existingAdmin.name {
                    updatedFields["name"] = name
                }
                
                if !email.isEmpty && email != existingAdmin.email {
                    updatedFields["email"] = email
                }
                
                if let newRole = role, newRole != existingAdmin.role {
                    updatedFields["role"] = newRole
                }
                
                if let newAccessLevel = accessLevel, newAccessLevel != existingAdmin.accessLevel {
                    updatedFields["accessLevel"] = newAccessLevel.rawValue
                }
                
                if !updatedFields.isEmpty {
                    try? await firestoreService.updateAdmin(userId: currentUserID, updatedFields: updatedFields)
                }
                
                // Update last active time
                try? await firestoreService.updateLastActive(userId: currentUserID)
            } else {
                // Create new admin if one doesn't exist
                let admin = Admin(
                    id: UUID().uuidString,
                    name: name.isEmpty ? "User" : name,
                    email: email.isEmpty ? (currentUser?.email ?? "") : email,
                    role: role,
                    accessLevel: accessLevel ?? .readonly
                )
                
                try? await firestoreService.addAdmin(userId: currentUserID, admin: admin)
            }
        }
    }
    
    // Fetch user info from Firestore
    @MainActor
    private func fetchUserFromFirestore() async {
        do {
            if let admin = try? await firestoreService.getAdmin(userId: currentUserID) {
                // Only update with data from Firestore if it's meaningful
                if !admin.name.isEmpty {
                    self.currentUser = UserInfo(from: admin)
                    saveUserInfoToDefaults()
                }
            } else if let email = UserDefaults.standard.string(forKey: "userEmail"), 
                      let name = UserDefaults.standard.string(forKey: "userName"),
                      !name.isEmpty {
                // Create new admin if none exists but we have some real data
                let accessLevelString = UserDefaults.standard.string(forKey: "userAccessLevel") ?? "READONLY"
                let accessLevel = Admin.AccessLevel(rawValue: accessLevelString) ?? .readonly
                let role = UserDefaults.standard.string(forKey: "userRole")
                let gender = UserDefaults.standard.string(forKey: "userGender")
                let number = UserDefaults.standard.integer(forKey: "userNumber")
                
                let admin = Admin(
                    id: UUID().uuidString,
                    name: name,
                    number: number > 0 ? number : nil,
                    email: email,
                    gender: gender,
                    role: role,
                    accessLevel: accessLevel
                )
                
                try? await firestoreService.addAdmin(userId: currentUserID, admin: admin)
                self.currentUser = UserInfo(from: admin)
                saveUserInfoToDefaults()
            } else if let authService = try? AuthService(), !authService.name.isEmpty {
                // Try to use name from the auth service if available
                let admin = try? await firestoreService.getOrCreateAdmin(
                    userId: currentUserID,
                    name: authService.name, 
                    email: authService.email
                )
                
                if let admin = admin {
                    self.currentUser = UserInfo(from: admin)
                    saveUserInfoToDefaults()
                }
            }
            // Do not create default placeholder admin if we can't find real data
        } catch {
            print("Error fetching admin data: \(error.localizedDescription)")
        }
    }
    
    // Save user info to UserDefaults
    private func saveUserInfoToDefaults() {
        guard let user = currentUser else { return }
        UserDefaults.standard.set(user.name, forKey: "userName")
        UserDefaults.standard.set(user.email, forKey: "userEmail")
        UserDefaults.standard.set(user.role, forKey: "userRole")
        UserDefaults.standard.set(user.accessLevel?.rawValue, forKey: "userAccessLevel")
        UserDefaults.standard.set(user.gender, forKey: "userGender")
        if let number = user.number {
            UserDefaults.standard.set(number, forKey: "userNumber")
        }
    }
    
    // Load user info from UserDefaults
    private func loadUserInfoFromDefaults() -> UserInfo? {
        guard !currentUserID.isEmpty else { return nil }
        
        let name = UserDefaults.standard.string(forKey: "userName") ?? "Hospital Admin"
        let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        let role = UserDefaults.standard.string(forKey: "userRole")
        let accessLevelString = UserDefaults.standard.string(forKey: "userAccessLevel") ?? "READONLY"
        let accessLevel = Admin.AccessLevel(rawValue: accessLevelString) ?? .readonly
        let gender = UserDefaults.standard.string(forKey: "userGender")
        let numberValue = UserDefaults.standard.integer(forKey: "userNumber")
        let number = numberValue > 0 ? numberValue : nil
        
        return UserInfo(
            id: currentUserID,
            name: name,
            email: email,
            role: role,
            accessLevel: accessLevel,
            gender: gender,
            number: number
        )
    }
}

// Mock AuthService for testing - would be replaced by real implementation
//class AuthService {
//    let name: String
//    let email: String
//    
//    init() throws {
//        self.name = "Test User"
//        self.email = "test@example.com"
//    }
//}
