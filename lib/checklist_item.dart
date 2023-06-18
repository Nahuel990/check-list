class ChecklistItem {
  final String id;
  final String title;
  bool isChecked;

  ChecklistItem({required this.id, required this.title, this.isChecked = false});
}
