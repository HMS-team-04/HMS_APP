import SwiftUI
import FirebaseCore

struct TestDashboardView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Service Test Views")) {
                    NavigationLink(destination: TestAdminView()) {
                        ServiceRowView(
                            title: "Admin Service",
                            description: "Test AdminFirestoreService functionality",
                            icon: "person.badge.shield.checkmark",
                            color: .blue
                        )
                    }
                    
                    NavigationLink(destination: TestDoctorView()) {
                        ServiceRowView(
                            title: "Doctor Service",
                            description: "Test DoctorService functionality",
                            icon: "stethoscope",
                            color: .green
                        )
                    }
                    
                    NavigationLink(destination: TestPatientView()) {
                        ServiceRowView(
                            title: "Patient Service",
                            description: "Test PatientDetails service",
                            icon: "person.crop.circle",
                            color: .orange
                        )
                    }
                    
                    NavigationLink(destination: TestStaffView()) {
                        ServiceRowView(
                            title: "Staff Service",
                            description: "Test StaffService functionality",
                            icon: "person.3",
                            color: .purple
                        )
                    }
                }
                
                Section(header: Text("Information")) {
                    Text("These test views allow you to test each service in isolation to verify functionality.")
                    Text("Each view provides create, read, and other operations for the specific service.")
                    Text("Data is stored in Firebase Firestore in the 'hms4' database.")
                }
            }
            .navigationTitle("HMS Service Tests")
            .listStyle(InsetGroupedListStyle())
            .onAppear {
                // Setup Firebase if needed
                if FirebaseApp.app() == nil {
                    FirebaseApp.configure()
                }
            }
        }
    }
}

struct ServiceRowView: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .cornerRadius(10)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    TestDashboardView()
} 