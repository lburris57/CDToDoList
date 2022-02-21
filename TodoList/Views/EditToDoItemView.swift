//
//  EditToDoItemView.swift
//  TodoList
//
//  Created by Larry Burris on 2/18/22.
//  Copyright © 2022 Larry Burris. All rights reserved.
//
import SwiftUI

struct EditToDoItemView: View
{
    // MARK: PROPERTIES
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var listViewModel: ListViewModel
    
    @State var title: String = Constants.EMPTY_STRING
    @State var category: String = Constants.EMPTY_STRING
    @State var description: String = Constants.EMPTY_STRING
    @State var selectedCategory:  String = Constants.EMPTY_STRING
    
    let toDoItem: ToDoItem
    
    // MARK: -
    // MARK: BODY
    var body: some View
    {
        NavigationView
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
                    }
                
                    VStack(alignment: .leading)
                    {
                        Text(" Title:")
                        
                        TextField("\(title)", text: $title)
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
                        .onAppear(perform: setValuesFromExistingToDoItem)
                    }

                    Button(action: updateButtonPressed, label:
                    {
                        Text("Update")
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
            .navigationTitle("Edit Item")
            .toolbar
            {
                ToolbarItem(placement: .navigationBarTrailing)
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
                
                ToolbarItem(placement: .cancellationAction)
                {
                    Button("Cancel")
                    {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: -
    // MARK: FUNCTIONS
    func updateButtonPressed()
    {
        toDoItem.toDoItemEntity.title = title
        toDoItem.toDoItemEntity.descriptionText = description
        
        listViewModel.updateItem(toDoItem: toDoItem, categoryName: selectedCategory)
        listViewModel.retrieveCategories()
        
        presentationMode.wrappedValue.dismiss()
    }

    func validateFields() -> Bool
    {
        if title == "" || description == ""
        {
            return false
        }
        
        return true
    }
    
    func setValuesFromExistingToDoItem()
    {
        title = toDoItem.title
        description = toDoItem.descriptionText
    }
}
