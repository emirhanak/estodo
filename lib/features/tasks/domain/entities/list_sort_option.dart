enum ListSortOption {
  manual,
  importance,
  dueDate,
  alphabetical,
  creationDate,
  myDay;

  String get label {
    return switch (this) {
      ListSortOption.manual => 'My order',
      ListSortOption.importance => 'Importance',
      ListSortOption.dueDate => 'Due date',
      ListSortOption.alphabetical => 'Alphabetically',
      ListSortOption.creationDate => 'Creation date',
      ListSortOption.myDay => 'Added to My Day',
    };
  }
}
