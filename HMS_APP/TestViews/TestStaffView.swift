import SwiftUI
import FirebaseCore
import FirebaseFirestore
import PhotosUI

struct TestStaffView: View {
    @StateObject private var staffService = StaffService()
    
    @State private var staffName = ""
    @State private var staffRole = ""
    @State private var education = ""
    @State private var dateOfBirth = Date()
    @State private var joinDate = Date()
    @State private var showDOBPicker = false
    @State private var showJoinDatePicker = false
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var certificateURLs: [URL] = []
    
    @State private var isLoading = false
    @State private var statusMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("StaffService Test")
                    .font(.title)
                    .padding(.bottom)
                
                Divider()
                
                // Input fields
                Group {
                    TextField("Staff Name", text: $staffName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Staff Role", text: $staffRole)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Education", text: $education)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        withAnimation {
                            showDOBPicker.toggle()
                        }
                    }) {
                        HStack {
                            Text("Date of Birth:")
                            Spacer()
                            Text(dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    if showDOBPicker {
                        DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                    
                    Button(action: {
                        withAnimation {
                            showJoinDatePicker.toggle()
                        }
                    }) {
                        HStack {
                            Text("Join Date:")
                            Spacer()
                            Text(joinDate.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    if showJoinDatePicker {
                        DatePicker("", selection: $joinDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                    
                    // Certificate picker
                    VStack(alignment: .leading) {
                        Text("Certificates:")
                        
                        PhotosPicker(selection: $selectedItems, matching: .images) {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text("Select Certificates")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if !certificateURLs.isEmpty {
                            Text("\(certificateURLs.count) certificate(s) selected")
                                .foregroundColor(.green)
                        }
                    }
                    .onChange(of: selectedItems) { items in
                        Task {
                            certificateURLs = []
                            for item in items {
                                if let data = try? await item.loadTransferable(type: Data.self) {
                                    // Save the file to temporary directory
                                    let fileName = "\(UUID().uuidString).jpg"
                                    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                                    try? data.write(to: fileURL)
                                    certificateURLs.append(fileURL)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                Group {
                    Button("Add Staff") {
                        addStaff()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(staffName.isEmpty || staffRole.isEmpty)
                    
                    Button("Fetch Staff") {
                        fetchStaff()
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Text("Status:")
                    Text(statusMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(statusMessage.contains("Error") ? .red : .green)
                }
                
                Divider()
                
                // Display fetched staff
                if !staffService.staffMembers.isEmpty {
                    Text("Fetched Staff (\(staffService.staffMembers.count)):")
                        .font(.headline)
                    
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(staffService.staffMembers) { staff in
                            StaffCardView(staff: staff)
                        }
                    }
                } else if !isLoading {
                    Text("No staff found")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
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
    
    private func addStaff() {
        isLoading = true
        statusMessage = "Adding staff member..."
        
        let certificates = certificateURLs.map { $0.lastPathComponent }
        
        let staff = Staff(
            id: UUID().uuidString,
            name: staffName,
            dateOfBirth: dateOfBirth,
            joinDate: joinDate,
            educationalQualification: education.isEmpty ? nil : education,
            certificates: certificates.isEmpty ? nil : certificates,
            staffRole: staffRole
        )
        
        staffService.addStaff(staff, certificateFiles: certificateURLs) { result in
            isLoading = false
            
            switch result {
            case .success:
                statusMessage = "Staff member added successfully!"
                // Clear the form
                staffName = ""
                staffRole = ""
                education = ""
                certificateURLs = []
                selectedItems = []
                // Fetch updated list
                fetchStaff()
            case .failure(let error):
                statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchStaff() {
        isLoading = true
        statusMessage = "Fetching staff members..."
        
        // Call the service
        staffService.fetchStaff()
        
        // Since the service doesn't provide a completion handler,
        // we'll simulate a delay before updating the UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            if self.staffService.staffMembers.isEmpty {
                self.statusMessage = "No staff members found"
            } else {
                self.statusMessage = "Fetched \(self.staffService.staffMembers.count) staff members!"
            }
        }
    }
}

struct StaffCardView: View {
    let staff: Staff
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(staff.name)
                .font(.headline)
            
            Group {
                if let role = staff.staffRole {
                    Text("Role: \(role)")
                }
                
                if let education = staff.educationalQualification {
                    Text("Education: \(education)")
                }
                
                if let certificates = staff.certificates, !certificates.isEmpty {
                    Text("Certificates: \(certificates.joined(separator: ", "))")
                }
                
                if let years = staff.yearsOfService {
                    Text("Years of service: \(years)")
                }
                
                if let dob = staff.dateOfBirth {
                    Text("DOB: \(dob.formatted(date: .abbreviated, time: .omitted))")
                }
                
                if let joinDate = staff.joinDate {
                    Text("Joined: \(joinDate.formatted(date: .abbreviated, time: .omitted))")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    TestStaffView()
} 