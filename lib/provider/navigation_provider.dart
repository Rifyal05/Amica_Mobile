import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  DateTime? _scrollToTopTime;
  DateTime? get scrollToTopTime => _scrollToTopTime;

  void setIndex(int index) {
    if (_selectedIndex == index) {
      _scrollToTopTime = DateTime.now();
    }
    _selectedIndex = index;
    notifyListeners();
  }
}