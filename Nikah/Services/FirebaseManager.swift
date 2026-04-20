// Services/FirebaseManager.swift

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FirebaseManager {
    static let shared = FirebaseManager()

    let auth: Auth
    let firestore: Firestore



    private init() {
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
    }

    // MARK: - Collection References
    var usersCollection: CollectionReference {
        firestore.collection("users")
    }

    var matchesCollection: CollectionReference {
        firestore.collection("matches")
    }

    var likesCollection: CollectionReference {
        firestore.collection("likes")
    }

    var requestsCollection: CollectionReference {
        firestore.collection("requests")
    }

    var reportsCollection: CollectionReference {
        firestore.collection("reports")
    }

    var shortlistsCollection: CollectionReference {
        firestore.collection("shortlists")
    }

    func messagesCollection(matchId: String) -> CollectionReference {
        firestore.collection("matches").document(matchId).collection("messages")
    }
}
