//
//  ListView.swift
//  TodoList
//
//  Created by Larry Burris on 02/14/22.
//  Copyright © 2022 Larry Burris. All rights reserved.
//
import SwiftUI

// Enums
enum SearchType: String, Identifiable, CaseIterable, Hashable
{
    var id: UUID
    {
        return UUID()
    }

    case noFilter = "No Filter"
    case notCompleted = "Not Completed"
    case completed = "Completed"
}

extension SearchType
{
    var searchType: String
    {
        switch self
        {
            case .noFilter:
                return "No Filter"
            case .notCompleted:
                return "Not Completed"
            case .completed:
                return "Completed"
        }
    }
}

enum SortOrder: String, Identifiable, CaseIterable, Hashable
{
    var id: UUID
    {
        return UUID()
    }

    case ascending = "Ascending"
    case descending = "Descending"
}

extension SortOrder
{
    var sortOrder: String
    {
        switch self
        {
            case .ascending:
                return "Ascending"
            case .descending:
                return "Descending"
        }
    }
}

struct ListView: View
{
    @EnvironmentObject var listViewModel: ListViewModel

    @State private var selectedSearchType: SearchType = .noFilter
    @State private var selectedSortOrder: SortOrder = .ascending
    @State private var isAscending: Bool = true
    @State private var toggleIcon: Bool = false
    @State private var isPresented: Bool = false
    @State private var selectedToDoItem: ToDoItem?
    @State private var toDoItemCategory: String = Constants.EMPTY_STRING
    @State private var categoryName: String = Constants.EMPTY_STRING
    @State private var showHeader: Bool = true

    func filterToDoItems()
    {
        Log.info("Selected filter type is \(selectedSearchType.searchType) and selected sort order is \(selectedSortOrder.sortOrder)")
        
        //  Save the selected filter/sort order values to UserFefaults
        listViewModel.saveToUserDefaults(key: Constants.FILTER_TYPE_KEY, value: selectedSearchType.searchType)
        listViewModel.saveToUserDefaults(key: Constants.SORT_ORDER_KEY, value: selectedSortOrder.sortOrder)
    
        listViewModel.filterPopulatedCategoryToDoItems()
    }

    func deleteItem(toDoItem: ToDoItem)
    {
        listViewModel.deleteItem(toDoItem: toDoItem)
    }

    func toggleButtonClicked()
    {
        toggleIcon.toggle()

        filterToDoItems()
    }

    var body: some View
    {
        NavigationView
        {
            ZStack
            {
                VStack(alignment: .leading)
                {
                    if listViewModel.toDoItems.isEmpty && listViewModel.isFiltered == false
                    {
                        NoToDoItemsView().transition(AnyTransition.opacity.animation(.easeIn))
                    }
                    else
                    {
                        if listViewModel.toDoItems.count > 0 || listViewModel.isFiltered == true
                        {
                            VStack(alignment: .leading, spacing: 0)
                            {
                                HStack
                                {
                                    Text(" Filter Type:").foregroundColor(Color.secondary)

                                    Picker("Search Type", selection: $selectedSearchType)
                                    {
                                        ForEach(SearchType.allCases)
                                        {
                                            searchType in

                                            Text(searchType.searchType).tag(searchType)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .onChange(of: selectedSearchType) { _ in filterToDoItems() }

                                    Button(action:
                                    {
                                        if selectedSortOrder == SortOrder.ascending
                                        {
                                            selectedSortOrder = SortOrder.descending
                                        }
                                        else
                                        {
                                            selectedSortOrder = SortOrder.ascending
                                        }

                                        toggleButtonClicked()
                                    })
                                    {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                            .rotationEffect(.degrees(toggleIcon ? 0.0 : 180.0))
                                            .animation(Animation.linear(duration: 0.2), value: toggleIcon)
                                    }

                                    Spacer()
                                }
                                .padding(.leading)
                            }
                        }

                        HStack
                        {
                            List
                            {
                                ForEach(listViewModel.populatedCategories)
                                {
                                    category in
                                    
                                    Section(header:

                                    HStack
                                    {
                                        Text(category.categoryName).foregroundColor(.blue)
                                    })
                                    {
                                        ForEach(category.filteredToDoItems)
                                        {
                                            toDoItem in

                                            ListRowView(toDoItem: toDoItem)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false)
                                            {
                                                Button("Delete")
                                                {
                                                    withAnimation(.easeInOut)
                                                    {
                                                        deleteItem(toDoItem: toDoItem)
                                                    }
                                                }
                                                .tint(.red)
                                            }
                                            .swipeActions(edge: .leading, allowsFullSwipe: false)
                                            {
                                                //  Don't edit completed items
                                                if !toDoItem.isCompleted
                                                {
                                                    Button("Edit")
                                                    {
                                                        selectedToDoItem = toDoItem
                                                    }
                                                    .tint(.blue)
                                                }
                                            }
                                            .onTapGesture
                                            {
                                                withAnimation(.linear)
                                                {
                                                    listViewModel.updateIsCompleted(toDoItem: toDoItem)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .refreshable
                            {
                                listViewModel.retrievePopulatedCategories()
                                listViewModel.retrieveToDoItems()
                            }
                            .frame(maxWidth: 800)
                            .listStyle(.sidebar)

                            Spacer()
                        }
                        .padding(.bottom)
                    }
                }.navigationTitle("To Do Items")
                .fullScreenCover(item: $selectedToDoItem)
                {
                    item in

                    EditToDoItemView(toDoItem: item)
                }
            }
            .toolbar
            {
                ToolbarItemGroup(placement: .navigationBarTrailing)
                {
                    HStack
                    {
                        listViewModel.toDoItems.isEmpty ? nil : NavigationLink(destination: AddToDoItemView())
                        {
                            Label("Add ToDoItem", systemImage: "plus.circle.fill").foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
}

struct ListView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ListView()
            .preferredColorScheme(.dark)
            .environmentObject(ListViewModel())
    }
}
