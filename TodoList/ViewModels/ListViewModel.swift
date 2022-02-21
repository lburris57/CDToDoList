//
//  ListViewModel.swift
//  TodoList
//
//  Created by Larry Burris on 02/14/22.
//  Copyright © 2022 Larry Burris. All rights reserved.
//
import Foundation
import CloudKit
import CoreData

class ListViewModel: ObservableObject
{
    let viewContext = CoreDataManager.shared.persistentContainer.viewContext
    
    @Published var userName: String = "Anonymous"
    @Published var toDoItems: [ToDoItem] = []
    @Published var categories: [Category] = []
    @Published var populatedCategories: [Category] = []
    
    let userNameKey: String = "userName"
    
    var isFiltered = false

    init()
    {
        initializeCategoryList()
        retrieveToDoItems()
        retrievePopulatedCategories()
        retrieveUserNameFromUserDefaults()
    }
    
    // MARK: -
    // MARK: Filter Functions
    func filterToDoItems(searchType: String, sortOrder: String)
    {
        Log.info("SearchType is '\(searchType)' and sortOrder is '\(sortOrder)'")
        
        retrieveToDoItems()
        retrievePopulatedCategories()
        
        if searchType == "Completed"
        {
            isFiltered = true
            
            toDoItems = toDoItems.filter {$0.isCompleted == true}.sorted(by:
            {
                lhs, rhs in
                
                return sortOrder == "Ascending" ? lhs.lastUpdated < rhs.lastUpdated : lhs.lastUpdated > rhs.lastUpdated
            })
        }
        else if searchType == "Not Completed"
        {
            isFiltered = true
            
            toDoItems = toDoItems.filter {$0.isCompleted == false}.sorted(by:
            {
                lhs, rhs in
                
                return sortOrder == "Ascending" ? lhs.lastUpdated < rhs.lastUpdated : lhs.lastUpdated > rhs.lastUpdated
            })
        }
        else
        {
            isFiltered = false
            
            toDoItems = toDoItems.sorted(by:
            {
                lhs, rhs in
                
                return sortOrder == "Ascending" ? lhs.lastUpdated < rhs.lastUpdated : lhs.lastUpdated > rhs.lastUpdated
            })
        }
    }
    
    // MARK: -
    // MARK: Retrieve Functions
    func retrieveUserNameFromUserDefaults()
    {
        guard let data = UserDefaults.standard.data(forKey: userNameKey),
              let savedUserName = try? JSONDecoder().decode(String.self, from: data)
        else
        {
            saveUserNameToUserDefaults("Anonymous")
            
            return
        }

        //  Set the current user name to the user name found in UserDefaults
        userName = savedUserName
        
        Log.info("Retrieved username from UserDefaults is: \(userName)")
    }

    func retrieveToDoItems()
    {
        toDoItems = ToDoItemEntity.all().map(ToDoItem.init)
    }
    
    func retrieveCategories()
    {
        categories = CategoryEntity.all().map(Category.init)
    }
    
    //  Categories with toDoItems
    func retrievePopulatedCategories()
    {
        for category in categories
        {
            if category.toDoItemsCount > 0
            {
                populatedCategories.append(category)
            }
        }
    }
    
    func retrieveCategoryEntityByCategoryName(categoryName: String) -> CategoryEntity?
    {
        for category in categories
        {
            if category.categoryName == categoryName
            {
                return category.categoryEntity
            }
        }
        
        return nil
    }

    // MARK: -
    // MARK: Delete Functions
    func deleteItem(indexSet: IndexSet)
    {
        var toDoItem: ToDoItem
        
        toDoItem = toDoItems[indexSet.first!]
        
        if let retrievedToDoItem = ToDoItemEntity.byId(id: toDoItem.id) as? ToDoItemEntity
        {
            //  Delete the database record and refresh the list from the database
            retrievedToDoItem.delete()
        
            retrieveToDoItems()
        }
    }
    
    func deleteItem(toDoItem: ToDoItem)
    {
        if let retrievedToDoItem = ToDoItemEntity.byId(id: toDoItem.id) as? ToDoItemEntity
        {
            //  Delete the database record and refresh the list from the database
            retrievedToDoItem.delete()
        
            retrieveToDoItems()
        }
    }
    
    // MARK: -
    // MARK: Add Functions
    func initializeCategoryList()
    {
        let defaultCategories = ["General", "Shopping List", "Home", "Errands", "Appointments", "Reminders"]
        
        retrieveCategories()
        
        //  Populate the Category table if empty
        if categories.isEmpty
        {
            for defaultCategory in defaultCategories
            {
                let categoryEntity: CategoryEntity = CategoryEntity(context: viewContext)
                
                categoryEntity.categoryName = defaultCategory
                categoryEntity.createdBy = Constants.SYSTEM
                categoryEntity.dateCreated = Date()
                categoryEntity.lastUpdated = Date()
                
                categoryEntity.save()
            }
        }
        
        retrieveCategories()
        
        Log.info("Size of category list is: \(categories.count)")
    }
    
    func addCategory(categoryName: String)
    {
        //  Don't allow duplicates
        for category in categories
        {
            if category.categoryName == categoryName
            {
                return
            }
        }
        
        //  Create a new CategoryEntity object
        let categoryEntity = CategoryEntity(context: viewContext)
        
        categoryEntity.categoryName = categoryName.capitalized
        categoryEntity.createdBy = userName
        categoryEntity.dateCreated = Date()
        categoryEntity.lastUpdated = Date()
        
        categoryEntity.save()
        
        retrieveToDoItems()
        
        filterToDoItems(searchType: "No Filter", sortOrder: "Ascending")
    }

    func addToDoItem(categoryName: String, title: String, description: String)
    {
        retrieveCategories()
        
        let categoryEntity = retrieveCategoryEntityByCategoryName(categoryName: categoryName)
        
        //  Create a new ToDoItemEntity object
        let toDoItemEntity = ToDoItemEntity(context: viewContext)
        
        toDoItemEntity.title = title.capitalized
        toDoItemEntity.descriptionText = description
        toDoItemEntity.createdBy = userName
        toDoItemEntity.isCompleted = false
        toDoItemEntity.dateCreated = Date()
        toDoItemEntity.lastUpdated = Date()
        toDoItemEntity.category = categoryEntity
        
        toDoItemEntity.save()
        
        retrieveToDoItems()
        
        filterToDoItems(searchType: "No Filter", sortOrder: "Ascending")
    }

    // MARK: -
    // MARK: Update Functions
    func updateIsCompleted(toDoItem: ToDoItem)
    {
        if let toDoItemEntity = ToDoItemEntity.byId(id: toDoItem.id) as? ToDoItemEntity
        {
            toDoItemEntity.isCompleted = !toDoItem.isCompleted
            toDoItemEntity.lastUpdated = Date()
            
            toDoItemEntity.save()
        }
        
        retrieveToDoItems()
    }
    
    func updateItem(toDoItem: ToDoItem, categoryName: String)
    {
        let categoryEntity = retrieveCategoryEntityByCategoryName(categoryName: categoryName)
        
        if let toDoItemEntity = ToDoItemEntity.byId(id: toDoItem.id) as? ToDoItemEntity
        {
            toDoItemEntity.title = toDoItem.title
            toDoItemEntity.descriptionText = toDoItem.descriptionText
            toDoItemEntity.lastUpdated = Date()
            toDoItemEntity.category = categoryEntity
            
            toDoItemEntity.save()
        }
        
        retrieveToDoItems()
        
        filterToDoItems(searchType: "No Filter", sortOrder: "Ascending")
    }
    
    // MARK: -
    // MARK: UserDefault Functions
    func saveUserNameToUserDefaults(_ userName: String)
    {
        if let encodedData = try? JSONEncoder().encode(userName)
        {
            UserDefaults.standard.set(encodedData, forKey: userNameKey)
        }
        
        retrieveUserNameFromUserDefaults()
        filterToDoItems(searchType: "No Filter", sortOrder: "Ascending")
    }
    
    func saveToUserDefaults<T: Encodable>(key: String, value: T)
    {
        if let encodedData = try? JSONEncoder().encode(value)
        {
            UserDefaults.standard.set(encodedData, forKey: key)
        }
    }
    
    func retrieveFromUserDefaults<T: Decodable>(key: String) -> T?
    {
        if let data = UserDefaults.standard.data(forKey: key),
           let retrievedData = try? JSONDecoder().decode(T.self, from: data)
        {
            return retrievedData
        }
        
        return nil
    }
}
 
