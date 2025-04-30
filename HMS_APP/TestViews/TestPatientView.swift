import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct TestPatientView: View {
    @StateObject private var patientService = PatientDetails()
    
    @State private var patientName = ""
    @State private var patientEmail = ""
    @State private var patientNumber = ""
    @State private var gender = "Male"
    @State private var dateOfBirth = Date()
    @State private var showDatePicker = false
    
    @State private var isLoading = false
    @State private var statusMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("PatientDetails Service Test")
                    .font(.title)
                    .padding(.bottom)
                
                Divider()
                
                // Input fields
                Group {
                    TextField("Patient Name", text: $patientName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Patient Email", text: $patientEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                    
                    TextField("Patient Number", text: $patientNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(.segmented)
                    
                    Button(action: {
                        withAnimation {
                            showDatePicker.toggle()
                        }
                    }) {
                        HStack {
                            Text("Date of Birth:")
                            Spacer()
                            Text(dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    if showDatePicker {
                        DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                }
                
                Divider()
                
                Group {
                    Button("Add Patient") {
                        addPatient()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(patientName.isEmpty || patientEmail.isEmpty)
                    
                    Button("Fetch Patients") {
                        fetchPatients()
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
                
                // Display fetched patients
                if !patientService.patients.isEmpty {
                    Text("Fetched Patients (\(patientService.patients.count)):")
                        .font(.headline)
                    
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(patientService.patients) { patient in
                            PatientCardView(patient: patient)
                        }
                    }
                } else if !isLoading {
                    Text("No patients found")
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
    
    private func addPatient() {
        isLoading = true
        statusMessage = "Adding patient..."
        
        let patient = Patient(
            id: UUID().uuidString,
            name: patientName,
            number: Int(patientNumber),
            email: patientEmail,
            dateOfBirth: dateOfBirth,
            gender: gender
        )
        
        patientService.addPatient(patient) { result in
            isLoading = false
            
            switch result {
            case .success:
                statusMessage = "Patient added successfully!"
                // Clear the form
                patientName = ""
                patientEmail = ""
                patientNumber = ""
                // Leave dateOfBirth and gender as is for convenience
                // Fetch updated list
                fetchPatients()
            case .failure(let error):
                statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchPatients() {
        isLoading = true
        statusMessage = "Fetching patients..."
        
        // Call the service
        patientService.fetchPatients()
        
        // Since the service doesn't provide a completion handler,
        // we'll simulate a delay before updating the UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            if self.patientService.patients.isEmpty {
                self.statusMessage = "No patients found"
            } else {
                self.statusMessage = "Fetched \(self.patientService.patients.count) patients!"
            }
        }
    }
}

struct PatientCardView: View {
    let patient: Patient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(patient.name)
                .font(.headline)
            
            Group {
                Text("Email: \(patient.email)")
                
                if let number = patient.number {
                    Text("ID: \(number)")
                }
                
                if let gender = patient.gender {
                    Text("Gender: \(gender)")
                }
                
                if let age = patient.age {
                    Text("Age: \(age) years")
                }
                
                if let dob = patient.dateOfBirth {
                    Text("DOB: \(dob.formatted(date: .abbreviated, time: .omitted))")
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
    TestPatientView()
} 