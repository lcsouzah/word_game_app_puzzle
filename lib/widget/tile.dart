//tile.dart


import 'package:flutter/material.dart';

class TileWidget extends StatelessWidget {
  final String letter;
  final VoidCallback onTap;

  const TileWidget({super.key, required this.letter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(1), // Add padding
        child: Card(
          elevation: 35, // Adds shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Round corners
            side: const BorderSide(color: Colors.white,width: 4), //add color and width here
          ),
          child: Container(
            decoration: const BoxDecoration(
              // Add gradient or solid color
              gradient: LinearGradient(
                colors: [Colors.deepPurple , Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(10)), // Match Card's borderRadius
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Text color
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

