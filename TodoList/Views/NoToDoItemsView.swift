//
//  NoToDoItemsView.swift
//  TodoList
//
//  Created by Larry Burris on 02/14/22.
//  Copyright © 2022 Larry Burris. All rights reserved.
//
import SwiftUI

struct NoToDoItemsView: View
{
    @EnvironmentObject var listViewModel: ListViewModel
    
    @State var animate: Bool = false
    @State private var isShowingAlert = false
    @State private var alertInput = ""

    var body: some View
    {
        NavigationView
        {
            ScrollView
            {
                VStack(spacing: 10)
                {
                    Text("There are no items to display!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: 400)
                .multilineTextAlignment(.center)
                .padding(40)
                .onAppear(perform: checkUserNameStatus)
            }
            .toolbar
            {
                HStack
                {
                    NavigationLink(destination: AddToDoItemView())
                    {
                        Label("Add ToDoItem", systemImage: "plus.circle.fill").foregroundColor(.blue)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .textFieldAlert(isShowing: $isShowingAlert, text: $alertInput, title: "Please Enter Your Name To Identify Items!")
        }
        
        Spacer()
    }
    
    func checkUserNameStatus()
    {
        if listViewModel.userName == "Anonymous"
        {
            isShowingAlert = true
        }
    }
}

struct TextFieldAlert<Presenting>: View where Presenting: View
{
    @EnvironmentObject var listViewModel: ListViewModel
    
    @Binding var isShowing: Bool
    @Binding var text: String
    
    let presenting: Presenting
    let title: String
    
    func saveUserName()
    {
        Log.info("User name value to be saved from text field alert is: \(text)")
        
        listViewModel.saveUserNameToUserDefaults(text)
    }

    var body: some View
    {
        GeometryReader
        {
            (_: GeometryProxy) in

            ZStack
            {
                self.presenting.disabled(isShowing)
                
                VStack
                {
                    Text(self.title)
                    
                    TextField("Anonymous", text: $text)
                        .padding(.horizontal)
                        .frame(height: 55)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .introspectTextField { textField in textField.becomeFirstResponder()}
                    
                    HStack
                    {
                        Button(action:
                        {
                            withAnimation
                            {
                                saveUserName()
                                isShowing.toggle()
                            }
                        })
                        {
                            Text("Save")
                        }
                        
                        Button("Cancel", role: .cancel, action:
                        {
                            withAnimation
                            {
                                isShowing.toggle()
                            }
                        })
                    }
                }
                .frame(maxWidth: 400)
                .padding()
                .shadow(radius: 5)
                .opacity(self.isShowing ? 1 : 0)
            }
        }
    }
}

extension View
{
    func textFieldAlert(isShowing: Binding<Bool>, text: Binding<String>, title: String) -> some View
    {
        TextFieldAlert(isShowing: isShowing, text: text, presenting: self, title: title)
    }
}
