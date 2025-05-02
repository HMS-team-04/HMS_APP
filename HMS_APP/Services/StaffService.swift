import Foundation
import FirebaseFirestore

class StaffService: ObservableObject {
    private let db = Firestore.firestore()
    private let collectionName = "hms4_staff"
    
    func setStaff(
        fullName: String,
        dateOfBirth: Date,
        dateOfJoining: Date,
        designation: String,
        email: String,
        education: String,
        certificateURLs: [URL],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let staffData: [String: Any] = [
            "name": fullName,
            "dateOfBirth": Timestamp(date: dateOfBirth),
            "dateOfJoining": Timestamp(date: dateOfJoining),
            "designation": designation,
            "email": email,
            "education": education,
            "certificates": certificateURLs.map { $0.absoluteString },
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection(collectionName).addDocument(data: staffData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
} 