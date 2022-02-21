//
//  ListRowView.swift
//  TodoList
//
//  Created by Larry Burris on 02/14/22.
//  Copyright © 2022 Larry Burris. All rights reserved.
//
import SwiftUI

struct ListRowView: View
{
    @EnvironmentObject var listViewModel: ListViewModel
    
    let toDoItem: ToDoItem
    
    var body: some View
    {
        VStack(alignment: .leading, spacing: 10)
        {
            HStack
            {
                Image(systemName: toDoItem.isCompleted ? "checkmark.circle.fill" : "circle").foregroundColor(.accentColor)
                
                Text(toDoItem.title)
            }
            .font(.callout)
            
            Text(toDoItem.category).font(.caption).fontWeight(.bold).padding(.horizontal, 20).foregroundColor(.secondary)
            
            Text(toDoItem.descriptionText).font(.callout).padding(.horizontal, 20).foregroundColor(.secondary)
            
            Text("Created by \(toDoItem.createdBy) on \(toDoItem.dateCreated)").font(.caption).padding(.horizontal, 20).foregroundColor(.secondary)
            
            if(toDoItem.isCompleted)
            {
                Text("Item completed on \(toDoItem.lastUpdated)").font(.callout).padding(.horizontal, 20).foregroundColor(.secondary)
            }
        }
    }
}
