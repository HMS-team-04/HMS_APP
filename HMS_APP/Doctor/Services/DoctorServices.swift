//
//  DoctorServices.swift
//  HMS_APP
//
//  Created by admin49 on 01/05/25.
//

import Foundation
import FirebaseFirestore

class DoctorServices: ObservableObject {
    @Published var doctors: [Doctor] = [] // Published property to store fetched doctors
    @Published var errorMessage: String? // Optional property to store error messages
    
    private let db = Firestore.firestore()
    
    /// Fetches doctors from the Firestore "hms4_doctors" collection
    /// and updates the published doctors array
    func fetchDoctors() async {
        do {
            let snapshot = try await db.collection("hms4_doctors").getDocuments()
            print(snapshot.documents)
            
            // Map Firestore documents to Doctor instances
            let doctors = snapshot.documents.compactMap { document in
                do {
                    let doctor = try document.data(as: Doctor.self)
                    print(doctor)
                    return doctor
                } catch {
                    print("Error decoding document \(document.documentID): \(error)")
                    return nil
                }
            }
            
            await MainActor.run {
                self.doctors = doctors
                self.errorMessage = nil 
            }
        } catch {
            print("Error fetching doctors: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func addHardcodedDoctor() async {
            do {
                // Create a hardcoded doctor
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                let dob = dateFormatter.date(from: "1980-06-15") // Date of birth
                let leaveDate1 = dateFormatter.date(from: "2025-06-01")
                let leaveDate2 = dateFormatter.date(from: "2025-06-10")
                
                let schedule = Doctor.Schedule(
                    leaveTimeSlots: [], // Empty for simplicity
                    fullDayLeaves: [leaveDate1, leaveDate2].compactMap { $0 }
                )
                
                let newDoctor = Doctor(
                    id: UUID().uuidString, // Unique ID for Firestore document
                    name: "Dr. Jane Doe",
                    number: 67890,
                    email: "dr.jane.doe@hospital.com",
                    licenseRegNo: "MED-67890-AB",
                    smc: "Medical Council of India",
                    gender: "Female",
                    dateOfBirth: dob,
                    yearOfRegistration: 2010,
                    schedule: schedule
                )
                
                // Save to Firestore
                try db.collection("hms4_doctors").document(newDoctor.id).setData(from: newDoctor)
                
                // Optionally, fetch doctors again to update the UI
                await fetchDoctors()
                
                // Clear any previous errors
                await MainActor.run {
                    self.errorMessage = nil
                }
            } catch {
                print("Error adding hardcoded doctor: \(error)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
}
