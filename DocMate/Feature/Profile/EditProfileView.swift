//
//  EditProfileView.swift
//  DocMate
//
//  Created by Naman Yadav on 16/03/26.
//
import SwiftUI

struct EditProfileView: View {
    
    @Environment(AppViewModel.self ) var viewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dob = Date()
    @State private var gender = ""
    
    var body: some View {
        NavigationStack {
            Form {
                
                // MARK: - Profile Image
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 100)
                            
                            Text(viewModel.user.initials)
                                .font(.system(size: 40))
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                
                // MARK: - Name
                Section{
                    HStack {
                        Text("First Name")
                        Spacer()
                        TextField("First Name", text: $firstName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.gray)
                    }
                    
                    HStack {
                        Text("Last Name")
                        Spacer()
                        TextField("Last Name", text: $lastName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.gray)
                    }
                    DatePicker(
                        "Date of Birth",
                        selection: $dob,
                        displayedComponents: .date
                    )
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(viewModel.genderOptions, id: \.self) { gender in
                            Text(gender)
                        }
                    }
                    
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            
            // MARK: - Toolbar
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.updateUser(
                                name: "\(firstName) \(lastName)",
                                dateOfBirth: dob,
                                gender: gender
                            )
                            dismiss()
                        }
                    } label: {
                        Text("Save")
                            .fontWeight(.regular)
                    }
                    .padding()
                    .foregroundStyle(.blue)
                    .buttonStyle(.plain)
                    
                }
            }
            
            // MARK: - Load Data
            .onAppear {
                let parts = viewModel.user.name.split(separator: " ")
                
                firstName = parts.first.map(String.init) ?? ""
                lastName = parts.dropFirst().joined(separator: " ")
                
                gender = viewModel.user.gender ?? "Male"
                
                if let dobString = viewModel.user.dateOfBirth {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    
                    dob = formatter.date(from: dobString) ?? Date()
                } else {
                    dob = Date()
                }
            }        }
    }
}
