//
//  DoctorModel.swift
//  Hms
//
//  Created by admin49 on 30/04/25.
//

import Foundation
import Firebase

/// A model representing a doctor in the healthcare system
struct Doctor: Identifiable, Codable {
    /// The unique identifier for the doctor, used by the Appwrite backend
    let id: String
    
    /// The doctor's full name
    let name: String
    
    /// The doctor's numeric identifier (optional)
    let number: Int?
    
    /// The doctor's email address for contact
    let email: String
    
    /// The doctor's medical speciality (e.g., Cardiology, Pediatrics, etc.)
    let speciality: String
    
    /// The doctor's license registration number
    let licenseRegNo: String?
    
    /// The doctor's State Medical Council
    let smc: String?
    
    /// The doctor's gender
    let gender: String?
    
    /// The doctor's date of birth
    let dateOfBirth: Date?
    
    /// The year the doctor got registered
    let yearOfRegistration: Int?
    
    /// The doctor's schedule information
    let schedule: Schedule?
    
    /// A structure to represent the doctor's schedule
    struct Schedule: Codable {
        /// Time slots when the doctor is on leave
        let leaveTimeSlots: [Date]?
        
        /// Full days when the doctor is on leave
        let fullDayLeaves: [Date]?
        
        init(leaveTimeSlots: [Date]? = nil, fullDayLeaves: [Date]? = nil) {
            self.leaveTimeSlots = leaveTimeSlots
            self.fullDayLeaves = fullDayLeaves
        }
    }
    
    /// Creates a new Doctor instance
    /// - Parameters:
    ///   - id: The unique identifier for the doctor
    ///   - name: The doctor's full name
    ///   - number: The doctor's numeric identifier (optional)
    ///   - email: The doctor's email address
    ///   - speciality: The doctor's medical speciality
    ///   - licenseRegNo: The doctor's license registration number (optional)
    ///   - smc: The doctor's State Medical Council (optional)
    ///   - gender: The doctor's gender (optional)
    ///   - dateOfBirth: The doctor's date of birth (optional)
    ///   - yearOfRegistration: The year the doctor got registered (optional)
    ///   - schedule: The doctor's schedule information (optional)
    init(
        id: String,
        name: String,
        number: Int? = nil,
        email: String,
        speciality: String,
        licenseRegNo: String? = nil,
        smc: String? = nil,
        gender: String? = nil,
        dateOfBirth: Date? = nil,
        yearOfRegistration: Int? = nil,
        schedule: Schedule? = nil
    ) {
        self.id = id
        self.name = name
        self.number = number
        self.email = email
        self.speciality = speciality
        self.licenseRegNo = licenseRegNo
        self.smc = smc
        self.gender = gender
        self.dateOfBirth = dateOfBirth
        self.yearOfRegistration = yearOfRegistration
        self.schedule = schedule
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case number
        case email
        case speciality
        case licenseRegNo = "licenseRegNo"
        case smc
        case gender
        case dateOfBirth = "dob"
        case yearOfRegistration
        case schedule
    }
    
    // MARK: - Additional functionality
    
    /// Calculates the doctor's age based on their date of birth (if available)
    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        return ageComponents.year
    }
    
    /// Returns a formatted string of the doctor's basic information
    var basicInfo: String {
        var info = name
        
        if let licenseRegNo = licenseRegNo {
            info += " (License: \(licenseRegNo))"
        }
        
        if let yearOfRegistration = yearOfRegistration {
            info += " - Registered: \(yearOfRegistration)"
        }
        
        return info
    }
    
    /// Checks if the doctor is available on a specific date
    /// - Parameter date: The date to check availability for
    /// - Returns: A boolean indicating if the doctor is available
    func isAvailable(on date: Date) -> Bool {
        guard let schedule = schedule else { return true }
        
        // Extract just the date component for full day comparison
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let justDate = calendar.date(from: dateComponents) ?? date
        
        // Check if the date is in the full day leaves list
        if let fullDayLeaves = schedule.fullDayLeaves,
           fullDayLeaves.contains(where: {
               let leaveComponents = calendar.dateComponents([.year, .month, .day], from: $0)
               let leaveDate = calendar.date(from: leaveComponents) ?? $0
               return leaveDate == justDate
           }) {
            return false
        }
        
        // Check if the specific time slot is in the leave time slots
        if let leaveTimeSlots = schedule.leaveTimeSlots {
            for leaveSlot in leaveTimeSlots {
                let leaveComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: leaveSlot)
                let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                
                if leaveComponents.year == dateComponents.year &&
                   leaveComponents.month == dateComponents.month &&
                   leaveComponents.day == dateComponents.day &&
                   leaveComponents.hour == dateComponents.hour &&
                   leaveComponents.minute == dateComponents.minute {
                    return false
                }
            }
        }
        
        return true
    }
}

// MARK: - Extensions for Doctor

extension Doctor {
    /// Creates a sample doctor for preview and testing purposes
    static var sample: Doctor {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dob = dateFormatter.date(from: "1975-03-20")
        
        // Create some sample leave dates
        let leaveDate1 = dateFormatter.date(from: "2025-05-15")
        let leaveDate2 = dateFormatter.date(from: "2025-05-25")
        
        // Create the schedule
        let schedule = Schedule(
            leaveTimeSlots: [],
            fullDayLeaves: [leaveDate1, leaveDate2].compactMap { $0 }
        )
        
        return Doctor(
            id: "doc123",
            name: "Dr. John Smith",
            number: 12345,
            email: "dr.john.smith@hospital.com",
            speciality: "Cardiology",
            licenseRegNo: "MED-12345-XY",
            smc: "Medical Council of India",
            gender: "Male",
            dateOfBirth: dob,
            yearOfRegistration: 2005,
            schedule: schedule
        )
    }
}

// MARK: - DoctorManager

class DoctorManager: ObservableObject {
    @Published var currentUserInfo: [String: Any]?
    @Published var currentDoctor: Doctor?
    @Published var error: String?
    @Published var isLicenseVerified = false
    
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    init() {
        Task {
            await fetchCurrentUserInfo()
            checkLicenseVerification()
        }
    }
    
    @MainActor
    func fetchCurrentUserInfo() async {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            self.error = "No user ID found"
            return
        }
        
        do {
            let docRef = db.collection("\(dbName)_doctors").document(userId)
            let document = try await docRef.getDocument()
            
            if document.exists, let data = document.data() {
                self.currentUserInfo = data
                
                // Parse date fields
                var dateOfBirth: Date? = nil
                if let dobTimestamp = data["dob"] as? Timestamp {
                    dateOfBirth = dobTimestamp.dateValue()
                }
                
                // Parse schedule data if it exists
                var schedule: Doctor.Schedule? = nil
                if let scheduleData = data["schedule"] as? [String: Any] {
                    var leaveTimeSlots: [Date] = []
                    var fullDayLeaves: [Date] = []
                    
                    // Parse leave time slots
                    if let leaveTimestamps = scheduleData["leaveTimeSlots"] as? [Timestamp] {
                        leaveTimeSlots = leaveTimestamps.map { $0.dateValue() }
                    }
                    
                    // Parse full day leaves
                    if let leaveTimestamps = scheduleData["fullDayLeaves"] as? [Timestamp] {
                        fullDayLeaves = leaveTimestamps.map { $0.dateValue() }
                    }
                    
                    schedule = Doctor.Schedule(
                        leaveTimeSlots: leaveTimeSlots.isEmpty ? nil : leaveTimeSlots,
                        fullDayLeaves: fullDayLeaves.isEmpty ? nil : fullDayLeaves
                    )
                }
                
                // Check license details
                if let licenseDetails = data["licenseDetails"] as? [String: Any],
                   let verificationStatus = licenseDetails["verificationStatus"] as? String {
                    self.isLicenseVerified = verificationStatus.lowercased() == "verified"
                } else {
                    self.isLicenseVerified = false
                }
                
                self.currentDoctor = Doctor(
                    id: document.documentID,
                    name: data["name"] as? String ?? "",
                    number: data["number"] as? Int,
                    email: data["email"] as? String ?? "",
                    speciality: data["speciality"] as? String ?? "",
                    licenseRegNo: data["licenseRegNo"] as? String,
                    smc: data["smc"] as? String,
                    gender: data["gender"] as? String,
                    dateOfBirth: dateOfBirth,
                    yearOfRegistration: data["yearOfRegistration"] as? Int,
                    schedule: schedule
                )
                
                self.error = nil
            } else {
                self.error = "Doctor data not found"
            }
        } catch {
            self.error = "Error fetching doctor info: \(error.localizedDescription)"
        }
    }
    
    func checkLicenseVerification() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        db.collection("\(dbName)_doctors").document(userId).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data(),
                  let licenseDetails = data["licenseDetails"] as? [String: Any],
                  let verificationStatus = licenseDetails["verificationStatus"] as? String else {
                DispatchQueue.main.async {
                    self?.isLicenseVerified = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.isLicenseVerified = verificationStatus.lowercased() == "verified"
            }
        }
    }
    
    func updateLicenseVerification(isVerified: Bool) {
        self.isLicenseVerified = isVerified
    }
}
