import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct TestAdminView: View {
    @State private var adminName = ""
    @State private var adminEmail = ""
    @State private var adminRole = ""
    @State private var accessLevel = "READONLY"
    @State private var userId = "F863FDAB-1869-4CDA-B638-5C0A626510AA"
    
    @State private var adminInfo: String = "No admin loaded"
    @State private var isLoading = false
    @State private var statusMessage = ""
    
    let service = AdminFirestoreService.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("AdminFirestoreService Test")
                    .font(.title)
                    .padding(.bottom)
                
                Group {
                    Text("Test User ID:")
                    Text(userId)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Divider()
                
                // Input fields
                Group {
                    TextField("Admin Name", text: $adminName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Admin Email", text: $adminEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                    
                    TextField("Admin Role", text: $adminRole)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Access Level", selection: $accessLevel) {
                        Text("Read Only").tag("READONLY")
                        Text("Support Admin").tag("SUPPORT_ADMIN")
                        Text("System Admin").tag("SYSTEM_ADMIN")
                        Text("Super Admin").tag("SUPER_ADMIN")
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider()
                
                Group {
                    Button("Add Admin") {
                        createAdmin()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(adminName.isEmpty || adminEmail.isEmpty)
                    
                    Button("Get Admin") {
                        getAdmin()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Update Last Active") {
                        updateLastActive()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Delete Admin") {
                        deleteAdmin()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                
                Divider()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Group {
                        Text("Status:")
                        Text(statusMessage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(statusMessage.contains("Error") ? .red : .green)
                        
                        Text("Admin Info:")
                        Text(adminInfo)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            // Set up Firebase
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
        }
    }
    
    private func createAdmin() {
        isLoading = true
        statusMessage = "Creating admin..."
        
        // Get access level enum
        let accessLevelEnum: Admin.AccessLevel
        switch accessLevel {
        case "SUPER_ADMIN":
            accessLevelEnum = .superAdmin
        case "SYSTEM_ADMIN":
            accessLevelEnum = .systemAdmin
        case "SUPPORT_ADMIN":
            accessLevelEnum = .supportAdmin
        default:
            accessLevelEnum = .readonly
        }
        
        let admin = Admin(
            id: UUID().uuidString,
            name: adminName,
            email: adminEmail,
            role: adminRole.isEmpty ? nil : adminRole,
            accessLevel: accessLevelEnum
        )
        
        Task {
            do {
                try await service.addAdmin(userId: userId, admin: admin)
                await MainActor.run {
                    isLoading = false
                    statusMessage = "Admin created successfully!"
                    getAdmin()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func getAdmin() {
        isLoading = true
        statusMessage = "Loading admin..."
        
        Task {
            do {
                if let admin = try await service.getAdmin(userId: userId) {
                    await MainActor.run {
                        isLoading = false
                        adminInfo = """
                        ID: \(admin.id)
                        Name: \(admin.name)
                        Email: \(admin.email)
                        Role: \(admin.role ?? "N/A")
                        Access Level: \(admin.accessLevel?.rawValue ?? "N/A")
                        Gender: \(admin.gender ?? "N/A")
                        Age: \(admin.age?.description ?? "N/A")
                        """
                        statusMessage = "Admin loaded successfully!"
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                        adminInfo = "No admin found with ID: \(userId)"
                        statusMessage = "Admin not found"
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func updateLastActive() {
        isLoading = true
        statusMessage = "Updating last active time..."
        
        Task {
            do {
                try await service.updateLastActive(userId: userId)
                await MainActor.run {
                    isLoading = false
                    statusMessage = "Last active time updated!"
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deleteAdmin() {
        isLoading = true
        statusMessage = "Deleting admin..."
        
        Task {
            do {
                try await service.deleteAdmin(userId: userId)
                await MainActor.run {
                    isLoading = false
                    adminInfo = "No admin loaded"
                    statusMessage = "Admin deleted successfully!"
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    TestAdminView()
} 
