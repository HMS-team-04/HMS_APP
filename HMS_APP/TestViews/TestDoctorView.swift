import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct TestDoctorView: View {
    @StateObject private var doctorService = DoctorService()
    
    @State private var doctorName = ""
    @State private var doctorEmail = ""
    @State private var licenseRegNo = ""
    @State private var gender = "Male"
    @State private var yearOfRegistration = ""
    
    @State private var isLoading = false
    @State private var statusMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("DoctorService Test")
                    .font(.title)
                    .padding(.bottom)
                
                Divider()
                
                // Input fields
                Group {
                    TextField("Doctor Name", text: $doctorName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Doctor Email", text: $doctorEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                    
                    TextField("License Registration #", text: $licenseRegNo)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(.segmented)
                    
                    TextField("Year of Registration", text: $yearOfRegistration)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                Divider()
                
                Group {
                    Button("Add Doctor") {
                        addDoctor()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(doctorName.isEmpty || doctorEmail.isEmpty)
                    
                    Button("Fetch Doctors") {
                        fetchDoctors()
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
                
                // Display fetched doctors
                if !doctorService.doctors.isEmpty {
                    Text("Fetched Doctors (\(doctorService.doctors.count)):")
                        .font(.headline)
                    
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(doctorService.doctors) { doctor in
                            DoctorCardView(doctor: doctor)
                        }
                    }
                } else if !isLoading {
                    Text("No doctors found")
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
    
    private func addDoctor() {
        isLoading = true
        statusMessage = "Adding doctor..."
        
        let doctor = Doctor(
            id: UUID().uuidString,
            name: doctorName,
            number: nil,
            email: doctorEmail,
            licenseRegNo: licenseRegNo.isEmpty ? nil : licenseRegNo,
            smc: nil,
            gender: gender,
            dateOfBirth: nil,
            yearOfRegistration: Int(yearOfRegistration)
        )
        
        doctorService.addDoctor(doctor) { result in
            isLoading = false
            
            switch result {
            case .success:
                statusMessage = "Doctor added successfully!"
                // Clear the form
                doctorName = ""
                doctorEmail = ""
                licenseRegNo = ""
                yearOfRegistration = ""
                // Fetch updated list
                fetchDoctors()
            case .failure(let error):
                statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchDoctors() {
        isLoading = true
        statusMessage = "Fetching doctors..."
        
        // Call the service
        doctorService.fetchDoctors()
        
        // Since the service doesn't provide a completion handler,
        // we'll simulate a delay before updating the UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            if self.doctorService.doctors.isEmpty {
                self.statusMessage = "No doctors found"
            } else {
                self.statusMessage = "Fetched \(self.doctorService.doctors.count) doctors!"
            }
        }
    }
}

struct DoctorCardView: View {
    let doctor: Doctor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(doctor.name)
                .font(.headline)
            
            Group {
                Text("Email: \(doctor.email)")
                
                if let licenseRegNo = doctor.licenseRegNo {
                    Text("License: \(licenseRegNo)")
                }
                
                if let gender = doctor.gender {
                    Text("Gender: \(gender)")
                }
                
                if let yearOfRegistration = doctor.yearOfRegistration {
                    Text("Registered: \(yearOfRegistration)")
                }
                
                if let age = doctor.age {
                    Text("Age: \(age) years")
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
    TestDoctorView()
} 