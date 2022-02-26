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
    
    /*
     
     How the filtering/sorting of the toDoItems in the populatedCategories array works
     
     0. Save the filter value "No Filter" and sort descriptor "Ascending" to UserDafaults when the app starts up
     1. Whenever a user selects a filter and/or a sort descriptor, save the values in UserDefaults
     2. Get the existing populatedCategoryList in the ListViewModel
     3. Spin through the populatedCategoryList and create a new category object with the same values from the existing one except for the item list
     4. Get the items from the existing category object
     5. Get the filter and sort descriptor values out of UserDefaults
     6. Sort the items based on the UserDefault values
     7. Add the newly sorted items to the new category object and add it to a new category list
     8. Replace the original populatedCategoryList with the new category list which will trigger the view to reload with the new data
     
     */
    
    @Published var userName: String = "Anonymous"
    @Published var toDoItems: [ToDoItem] = []
    @Published var categories: [Category] = []
    @Published var populatedCategories: [Category] = []
    
    var filterType = Constants.EMPTY_STRING
    var sortOrder = Constants.EMPTY_STRING
    
    var isFiltered = false

    init()
    {
        //  Remove any duplicate category entities
        removeDuplicateCategoryEntities()
        
        initializeCategoryList()
        
        retrieveToDoItems()
        retrievePopulatedCategories()
        retrieveUserNameFromUserDefaults()
        setFilterAndSortValuesToUserDefaults(filterType: filterType, sortOrder: sortOrder)
        saveToUserDefaults(key: Constants.FILTER_TYPE_KEY, value: "No Filter")
        saveToUserDefaults(key: Constants.SORT_ORDER_KEY, value: "Ascending")
        
        getFilterAndSortValuesFromUserDefaults()
        
        filterPopulatedCategoryToDoItems()
    }
    
    func removeDuplicateCategoryEntities()
    {
        var categoryEntities = CategoryEntity.all() as [CategoryEntity]
        
        var categoryNames: [String] = []
        
        for categoryEntity in categoryEntities
        {
            let categoryName = categoryEntity.categoryName!
            
            if categoryEntity.toDoItems?.count == 0
            {
                if !categoryNames.contains(categoryName) && categoryName != "Home" && categoryName != "Programming"
                {
                    categoryNames.append(categoryName)
                }
                else
                {
                    categoryEntity.delete()
                }
            }
        }
    }
    
    // MARK: -
    // MARK: Filter/sort values to/from UserDefaults Functions
    func setFilterAndSortValuesToUserDefaults(filterType: String, sortOrder: String)
    {
        saveToUserDefaults(key: Constants.FILTER_TYPE_KEY, value: "No Filter")
        saveToUserDefaults(key: Constants.SORT_ORDER_KEY, value: "Ascending")
    }
    
    func getFilterAndSortValuesFromUserDefaults()
    {
        self.filterType = retrieveFromUserDefaults(key: Constants.FILTER_TYPE_KEY) ?? "No Filter"
        self.sortOrder = retrieveFromUserDefaults(key: Constants.SORT_ORDER_KEY) ?? "Ascending"
    }
    
    // MARK: -
    // MARK: Filter Functions
    func filterPopulatedCategoryToDoItems()
    {
        getFilterAndSortValuesFromUserDefaults()
        
        var filteredPopulatedCategories: [Category] = []
        
        Log.info("Size of populated categories array is: \(populatedCategories.count)")
        
        for populatedCategory in populatedCategories
        {
            let toDoItemList = populatedCategory.toDoItems
            
            Log.info("Size of existing todoItems in \(populatedCategory.categoryName) is: \(toDoItemList.count)")
            
            var category: Category = Category(categoryEntity: populatedCategory.categoryEntity)
            
            let filteredToDoItems = filterToDoItems(filterType: filterType, sortOrder: sortOrder, toDoItems: toDoItemList)
            
            category.filteredToDoItems = filteredToDoItems
            
            filteredPopulatedCategories.append(category)
        }
        
        //  Replace the existing populatedCategories with the filtered populated categories
        populatedCategories.removeAll()
        populatedCategories.append(contentsOf: filteredPopulatedCategories)
        
        Log.info("Size of filtered populated categories is: \(populatedCategories)")
    }
    
    func filterToDoItems(filterType: String, sortOrder: String, toDoItems: [ToDoItem]) -> [ToDoItem]
    {
        Log.info("FilterType is '\(filterType)' and sortOrder is '\(sortOrder)'")
        
        var filteredToDoItems: [ToDoItem] = []
        
        if filterType == "Completed"
        {
            isFiltered = true
            
            filteredToDoItems = toDoItems.filter {$0.isCompleted == true}.sorted(by:
            {
                lhs, rhs in
                
                return sortOrder == "Ascending" ? lhs.lastUpdated < rhs.lastUpdated : lhs.lastUpdated > rhs.lastUpdated
            })
        }
        else if filterType == "Not Completed"
        {
            isFiltered = true
            
            filteredToDoItems = toDoItems.filter {$0.isCompleted == false}.sorted(by:
            {
                lhs, rhs in
                
                return sortOrder == "Ascending" ? lhs.lastUpdated < rhs.lastUpdated : lhs.lastUpdated > rhs.lastUpdated
            })
        }
        else
        {
            isFiltered = false
            
            filteredToDoItems = toDoItems.sorted(by:
            {
                lhs, rhs in
                
                return sortOrder == "Ascending" ? lhs.lastUpdated < rhs.lastUpdated : lhs.lastUpdated > rhs.lastUpdated
            })
        }
        
        return filteredToDoItems
    }
    
    func filterToDoItems(searchType: String, sortOrder: String)
    {
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
        guard let data = UserDefaults.standard.data(forKey: Constants.USER_NAME_KEY),
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
        let categoryEntities = CategoryEntity.all() as [CategoryEntity]
        
        var categoryList: [Category] = []
        
        for categoryEntity in categoryEntities
        {
            let category = Category(categoryEntity: categoryEntity)
            
            categoryList.append(category)
        }
        
        categories = categoryList
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
            filterPopulatedCategoryToDoItems()
        }
    }
    
    func deleteItem(toDoItem: ToDoItem)
    {
        if let retrievedToDoItem = ToDoItemEntity.byId(id: toDoItem.id) as? ToDoItemEntity
        {
            //  Delete the database record and refresh the list from the database
            retrievedToDoItem.delete()
        
            retrieveToDoItems()
            filterPopulatedCategoryToDoItems()
        }
    }
    
    // MARK: -
    // MARK: Add Functions
    func initializeCategoryList()
    {
        let defaultCategories = ["General", "Shopping List", "Home", "Errands", "Appointments", "Reminders", "Programming"]
        
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
        
        //  Add the toDoItem to the categoryEntity and save it
        if let categoryEntity = retrieveCategoryEntityByCategoryName(categoryName: categoryName)
        {
            categoryEntity.toDoItems?.adding(toDoItemEntity)

            categoryEntity.save()
        }
        
        retrieveToDoItems()
        
        filterPopulatedCategoryToDoItems()
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
            
            //  Add the toDoItem to the categoryEntity and save it
            if let categoryEntity = retrieveCategoryEntityByCategoryName(categoryName: categoryName)
            {
                categoryEntity.toDoItems?.adding(toDoItemEntity)

                categoryEntity.save()
            }
        }
        
        retrieveToDoItems()
        
        filterPopulatedCategoryToDoItems()
    }
    
    // MARK: -
    // MARK: UserDefault Functions
    func saveUserNameToUserDefaults(_ userName: String)
    {
        if let encodedData = try? JSONEncoder().encode(userName)
        {
            UserDefaults.standard.set(encodedData, forKey: Constants.USER_NAME_KEY)
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
    
    func retrieveFromUserDefaults(key: String) -> String?
    {
        if let data = UserDefaults.standard.data(forKey: key),
           let retrievedData = try? JSONDecoder().decode(String.self, from: data)
        {
            return retrievedData
        }
        
        return nil
    }
}
 
