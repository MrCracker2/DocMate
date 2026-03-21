//
//  HomeView.swift
//  DocMate
//
//  Created by Shashwat kumar on 19/03/26.
//

import SwiftUI

struct HomeView: View {
    
    @Environment(AppViewModel.self ) var viewModel
    @State private var showProfileView:Bool = false
    
    // MARK: Grid Layouts
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    let rows = [
        GridItem(.fixed(160))
    ]
    
    // MARK: Date Formatter
    
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    func formatDate(_ date: Date) -> String {
        Self.formatter.string(from: date)
    }
    
    
    // MARK: UI
    
    var body: some View {
            
            ScrollView (showsIndicators: false){
                
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: Attention Required
                    
                    Text("Attention Required")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        
                        LazyHGrid(rows: rows, spacing: 16) {
                            
                            ForEach(viewModel.expiringDocuments) { doc in
                                
                                if let due = doc.dueDate {
                                    
                                    NavigationLink(destination: DocumentDetailView(document: doc)) {
                                        DocumentCard(
                                            icon: "doc.text",
                                            title: doc.name,
                                            dueDate: formatDate(due)
                                        )
                                        .frame(width: 160)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    
                    // MARK: Recently Saved
                    
                    HStack {
                        Text("Recently Saved")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        
                        
                        if viewModel.recentDocuments.count > 4 {
                            NavigationLink(destination: RecentlySavedView()) {
                                Image(systemName: "chevron.right")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        
                        ForEach(Array(viewModel.recentDocuments.prefix(4))) { doc in
                            
                            NavigationLink(destination: DocumentDetailView(document: doc)) {
                                DocumentCard(
                                    icon: "doc.text",
                                    title: doc.name,
                                )
                            }
                            .buttonStyle(.plain)

                        }
                    }
                    
                    
                    // MARK: Pinned Documents
                    
                    HStack {
                        Text("Pinned Documents")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        
                        
                        if viewModel.pinnedDocuments.count > 5 {
                            NavigationLink(destination: PinnedView()) {
                                Image(systemName: "chevron.right")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        
                        LazyHGrid(rows: rows, spacing: 16) {
                            
                            ForEach(Array(viewModel.pinnedDocuments.prefix(5))) { doc in
                                
                                NavigationLink(destination: DocumentDetailView(document: doc)) {
                                    DocumentCard(
                                        icon: "doc.text",
                                        title: doc.name,
                                    )
                                    .frame(width: 160)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                }
                .padding()
            }
            
            .navigationTitle("Home")
            
            .toolbar {
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    
                    Button {
                        print("Add tapped")
                    } label: {
                        Image(systemName: "plus")
                    }
                    Button{
                        showProfileView = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 37)
                            
                            Text(viewModel.user.initials)
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                    }
                }
            }
        
        .sheet(isPresented: $showProfileView) {
            ProfileView()
        }
    }
}

// MARK: Preview

#Preview {
    HomeView()
        .environment(AppViewModel())
}
