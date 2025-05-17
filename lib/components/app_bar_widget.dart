import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget {
  const AppBarWidget({
    super.key,
    required this.style,
    required this.theme,
    required this.onTap,
  });

  final TextStyle style;
  final ThemeData theme;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      title: Text("Timetable", style: style),
      centerTitle: true,
      leading: GestureDetector(
        child: Icon(Icons.menu, color: theme.colorScheme.onSecondary),
      ),
      actions: [
        GestureDetector(
          onTap: () => onTap(),
          child: AspectRatio(
            aspectRatio: 1 / 1,
            child: Center(
              child: Icon(
                Icons.refresh,
                color: theme.colorScheme.onSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
