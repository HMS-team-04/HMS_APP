//
//  Patient.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 30/04/25.
//


import Foundation

/// A model representing a patient in the healthcare system
struct Patient: Identifiable, Codable {
    /// The unique identifier for the patient, used by the Appwrite backend
    let id: String
    
    /// The patient's full name
    let name: String
    
    /// The patient's numeric identifier (could be used for medical record number)
    let number: Int?
    
    /// The patient's email address for contact
    let email: String
    
    /// The patient's date of birth
    let dateOfBirth: Date?
    
    /// The patient's gender
    let gender: String?
    
    /// Creates a new Patient instance
    /// - Parameters:
    ///   - id: The unique identifier for the patient
    ///   - name: The patient's full name
    ///   - number: The patient's numeric identifier (optional)
    ///   - email: The patient's email address
    ///   - dateOfBirth: The patient's date of birth (optional)
    ///   - gender: The patient's gender (optional)
    init(id: String, name: String, number: Int? = nil, email: String, dateOfBirth: Date? = nil, gender: String? = nil) {
        self.id = id
        self.name = name
        self.number = number
        self.email = email
        self.dateOfBirth = dateOfBirth
        self.gender = gender
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case number
        case email
        case dateOfBirth = "dob"
        case gender
    }
    
    // MARK: - Additional functionality
    
    /// Calculates the patient's age based on their date of birth (if available)
    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        return ageComponents.year
    }
    
    /// Returns a formatted string of the patient's basic information
    var basicInfo: String {
        var info = name
        
        if let age = age {
            info += " (Age: \(age)"
            
            if let gender = gender {
                info += ", \(gender)"
            }
            
            info += ")"
        } else if let gender = gender {
            info += " (\(gender))"
        }
        
        return info
    }
}

// MARK: - Extensions for Patient

extension Patient {
    /// Creates a sample patient for preview and testing purposes
    static var sample: Patient {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dob = dateFormatter.date(from: "1985-06-15") ?? Date()
        
        return Patient(
            id: "sample123",
            name: "Jane Doe",
            number: 10042,
            email: "jane.doe@example.com",
            dateOfBirth: dob,
            gender: "Female"
        )
    }
}