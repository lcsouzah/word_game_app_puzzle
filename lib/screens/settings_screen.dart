import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<Color> _colors = [
    Colors.blueGrey,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
  ];
  Color _selectedColor = Colors.blueGrey;

  @override
  void initState() {
    super.initState();
    _loadColor();
  }

  Future<void> _loadColor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt('tileColor');
    if (value != null) {
      setState(() {
        _selectedColor = Color(value);
      });
    }
  }

  Future<void> _saveColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tileColor', color.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(16),
        children: _colors.map((color) {
          final bool isSelected = _selectedColor.value == color.value;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
              _saveColor(color);
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}