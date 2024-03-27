//
//  FirebaseTestFunction.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/3/23.
//

import Foundation
import Firebase

func getPathsInFirebaseDatabase(reference: DatabaseReference = Database.database().reference(), path: String = "") {
    
    // Fetch the data from Firebase database at the specified path
    reference.child(path).observeSingleEvent(of: .value, with: { snapshot in
        
        // Check if the snapshot exists
        guard snapshot.exists() else {
            return
        }
        
        // Get the keys at the current level
        let keys = snapshot.children.allObjects.compactMap { ($0 as? DataSnapshot)?.key }
        
        // Print the current path
        print(path)
        
//        // Loop through each key at the current level
//        for key in keys {
//
//            // Create the child path by appending the key to the current path
//            let childPath = (path == "") ? key : "\(path)/\(key)"
//
//            // Recursively fetch the data at the child path
//            getPathsInFirebaseDatabase(reference: reference, path: childPath)
//        }
    })
}
