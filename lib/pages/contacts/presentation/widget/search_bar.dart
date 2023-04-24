import 'package:flutter/material.dart';

typedef OnSearchBarChanged = void Function(String searchKeyword);

class SearchBar extends StatefulWidget {
  final OnSearchBarChanged onSearchBarChanged;

  const SearchBar({
    Key? key,
    required this.onSearchBarChanged
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late final TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
    textEditingController.addListener(() {
      widget.onSearchBarChanged(textEditingController.text);
    });
  }

  @override
  void dispose() {
    super.dispose();
    textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: textEditingController,
      decoration: InputDecoration(
        hintText: 'Search'
      ),
    );
  }

}