import 'package:flutter/material.dart';
import '../models/player.dart';

class PlayerSpinner extends StatefulWidget {
  final List<Player> players;
  final Function(Player) onPlayerSelected;

  const PlayerSpinner({
    super.key,
    required this.players,
    required this.onPlayerSelected,
  });

  @override
  State<PlayerSpinner> createState() => _PlayerSpinnerState();
}

class _PlayerSpinnerState extends State<PlayerSpinner> {
  int _selectedIndex = 0;

  void _spin() {
    if (widget.players.isEmpty) return;
    final next = (DateTime.now().millisecondsSinceEpoch) % widget.players.length;
    setState(() => _selectedIndex = next);
    widget.onPlayerSelected(widget.players[next]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.players.isEmpty) {
      return const Text('No players added!', style: TextStyle(color: Colors.white));
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 180,
          child: Center(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: widget.players.map((p) {
                  final isSelected = widget.players[_selectedIndex].id == p.id;
                  return ChoiceChip(
                    label: Text(p.name, style: const TextStyle(fontSize: 16)),
                    selected: isSelected,
                    onSelected: (_) {
                      widget.onPlayerSelected(p);
                    },
                    selectedColor: const Color(0xFFFF0080),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: _spin,
          icon: const Icon(Icons.casino),
          label: const Text('SPIN / SELECT PLAYER'),
        ),
      ],
    );
  }
}
