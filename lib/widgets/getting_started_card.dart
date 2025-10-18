import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GettingStartedCard extends StatefulWidget {
  const GettingStartedCard({super.key});

  @override
  State<GettingStartedCard> createState() => _GettingStartedCardState();
}

class _GettingStartedCardState extends State<GettingStartedCard> {
  static const _prefsKey = 'getting_started_card_hidden';

  bool _isVisible = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadVisibility();
  }

  Future<void> _loadVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getBool(_prefsKey) ?? false;
    if (!mounted) return;
    setState(() {
      _isVisible = !hidden;
      _initialized = true;
    });
  }

  Future<void> _hideCard() async {
    if (!_isVisible) return;
    setState(() {
      _isVisible = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || !_isVisible) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Empezar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _hideCard,
                ),
              ],
            ),
            const Text('¡Bienvenido a tu nueva cuenta! Te mostraremos los alrededores.'),
          ],
        ),
      ),
    );
  }
}
