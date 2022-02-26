//
//  AddToDoItemView.swift
//  TodoList
//
//  Created by Larry Burris on 02/14/22.
//  Copyright © 2022 Larry Burris. All rights reserved.
//
import SwiftUI
import Introspect

struct AddToDoItemView: View
{
    // MARK: PROPERTIES
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var listViewModel: ListViewModel
    
    @State var title: String = Constants.EMPTY_STRING
    @State var description: String = Constants.EMPTY_STRING
    @State var category: String = Constants.EMPTY_STRING
    @State var alertTitle: String = Constants.EMPTY_STRING
    @State var showAlert: Bool = false
    @State var showCategoryTextField: Bool = false
    @State var selectedCategory: String = "General"
    
    // MARK: -
    // MARK: BODY
    var body: some View
    {
        ScrollView
        {
            VStack(alignment: .leading, spacing: 20)
            {
                HStack
                {
                    Text(" Category:")
                    
                    Picker("Category", selection: $selectedCategory)
                    {
                        ForEach(listViewModel.categories)
                        {
                            category in

                            Text(category.categoryName).tag(category.categoryName)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedCategory) { value in selectedCategory = value }
                    
                    Spacer()
                }
                
                if showCategoryTextField
                {
                    VStack(alignment: .leading)
                    {
                        Text(" Category:")
                        
                        TextField("Please enter a new category...", text: $category)
                            .introspectTextField { textField in textField.becomeFirstResponder()}
                            .padding(.horizontal)
                            .frame(maxWidth: 400)
                            .frame(height: 55)
                            .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }

                VStack(alignment: .leading)
                {
                    Text(" Title:")
                    
                        TextField("Please enter a title...", text: $title)
                            .introspectTextField { textField in textField.becomeFirstResponder()}
                            .padding(.horizontal)
                            .frame(maxWidth: 400)
                            .frame(height: 55)
                            .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                }
                
                VStack(alignment: .leading)
                {
                    Text(" Description:")
                    
                    TextEditor(text: $description)
                    .padding(.horizontal)
                    .lineLimit(10)
                    .frame(maxWidth: 400)
                    .frame(height: 125)
                    .background(Color(UIColor.secondarySystemBackground))
                    .border(Color.accentColor, width: 1)
                }

                Button(action: saveButtonPressed, label:
                {
                    Text("Save")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(height: 55)
                        .frame(maxWidth: 400)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                        .shadow(
                            color:Color.accentColor.opacity(0.7),
                            radius: 20,
                            x: 0,
                            y: 20)
                        
                }).disabled(!validateFields())
            }
            .padding(14)
        }
        .navigationTitle("Add Item")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert, content: getAlert)
        .toolbar
        {
            ToolbarItemGroup(placement: .navigationBarTrailing)
            {
                NavigationLink(destination: AddCategoryView())
                {
                    HStack
                    {
                        Text("Add Category").foregroundColor(.blue)
                        Label("Add Category", systemImage: "plus.circle.fill").foregroundColor(.blue)
                    }
                }
            }
        }
    }

    // MARK: -
    // MARK: FUNCTIONS
    func saveButtonPressed()
    {
        listViewModel.addToDoItem(categoryName: selectedCategory, title: title, description: description)
        
        presentationMode.wrappedValue.dismiss()
    }

    func validateFields() -> Bool
    {
        if title == Constants.EMPTY_STRING || description == Constants.EMPTY_STRING
        {
            return false
        }
        
        return true
    }

    func getAlert() -> Alert
    {
        return Alert(title: Text(alertTitle))
    }
}

// MARK: -
// MARK: PREVIEW
struct AddView_Previews: PreviewProvider
{
    static var previews: some View
    {
        AddToDoItemView()
        .preferredColorScheme(.dark)
        .environmentObject(ListViewModel())
    }
}
