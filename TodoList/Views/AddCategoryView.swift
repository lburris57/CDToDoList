//
//  AddCategoryView.swift
//  TodoList
//
//  Created by Larry Burris on 2/20/22.
//  Copyright © 2022 Larry Burris. All rights reserved.
//
import SwiftUI

struct AddCategoryView: View
{
    // MARK: PROPERTIES
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var listViewModel: ListViewModel
    
    @State var categoryName: String = Constants.EMPTY_STRING
    
    var body: some View
    {
        VStack(alignment: .leading, spacing: 20)
        {
            VStack(alignment: .leading)
            {
                Text(" Category Name:")
                
                TextField("Please enter a new category name...", text: $categoryName)
                    .introspectTextField { textField in textField.becomeFirstResponder()}
                    .padding(.horizontal)
                    .frame(maxWidth: 400)
                    .frame(height: 55)
                    .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
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
        .navigationTitle("Add Category")
        .navigationBarTitleDisplayMode(.inline)
        .padding(20)
        
        Spacer()
    }
    
    // MARK: -
    // MARK: FUNCTIONS
    func saveButtonPressed()
    {
        listViewModel.addCategory(categoryName: categoryName)
        
        listViewModel.retrieveCategories()
        
        presentationMode.wrappedValue.dismiss()
    }

    func validateFields() -> Bool
    {
        if categoryName == Constants.EMPTY_STRING
        {
            return false
        }
        
        return true
    }
}

struct AddCategoryView_Previews: PreviewProvider
{
    static var previews: some View
    {
        AddCategoryView()
        .preferredColorScheme(.dark)
        .environmentObject(ListViewModel())
    }
}
