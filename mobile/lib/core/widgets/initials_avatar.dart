import 'package:flutter/material.dart';

/// "Ramesh Kumar Reddy" → "RR" (first letters of the first and last name); "Ramesh" → "R"; none → null.
String? initialsOf(String? name) {
  final words = (name ?? '').trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return null;
  final first = words.first.characters.first;
  final last = words.length > 1 ? words.last.characters.first : '';
  return (first + last).toUpperCase();
}

/// Round avatar with the person's initials, or a person icon when there is no name yet.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.radius = 20});
  final String? name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = initialsOf(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: initials == null
          ? Icon(Icons.person, size: radius * 1.1)
          : Text(initials, style: TextStyle(fontSize: radius * .75, fontWeight: FontWeight.w700)),
    );
  }
}
