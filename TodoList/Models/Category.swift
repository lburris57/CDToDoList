//
//  Category.swift
//  TodoList
//
//  Created by Larry Burris on 2/18/22.
//  Copyright © 2022 Larry Burris. All rights reserved.
//
import CoreData
import Foundation

//  Presentation layer struct that has computed fields that
//  return the values from the CategoryEntity database class
struct Category: Identifiable
{
    let categoryEntity: CategoryEntity
    
    var filteredToDoItems: [ToDoItem] = []

    var id: NSManagedObjectID
    {
        return categoryEntity.objectID
    }

    var categoryName: String
    {
        return categoryEntity.categoryName ?? Constants.EMPTY_STRING
    }

    var dateCreated: String
    {
        return categoryEntity.dateCreated?.asShortDateFormattedString() ?? Constants.EMPTY_STRING
    }

    var lastUpdated: String
    {
        return categoryEntity.lastUpdated?.asLongDateFormattedString() ?? Constants.EMPTY_STRING
    }

    var toDoItemsCount: Int
    {
        return categoryEntity.toDoItems?.count ?? 0
    }

    var toDoItemEntities: [ToDoItemEntity]
    {
        let toDoItemEntitySet = categoryEntity.toDoItems as? Set<ToDoItemEntity> ?? []
        
        return toDoItemEntitySet.sorted { $0.category?.categoryName ?? Constants.EMPTY_STRING < $1.category?.categoryName ?? Constants.EMPTY_STRING }
    }
    
    var toDoItems: [ToDoItem]
    {
        return toDoItemEntities.map(ToDoItem.init)
    }
}
