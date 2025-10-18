import 'package:flutter/material.dart';

class GettingStartedCard extends StatefulWidget {
  const GettingStartedCard({super.key});

  @override
  State<GettingStartedCard> createState() => _GettingStartedCardState();
}

class _GettingStartedCardState extends State<GettingStartedCard> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _isVisible,
      child: Card(
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
                    onPressed: () {
                      setState(() {
                        _isVisible = false;
                      });
                    },
                  ),
                ],
              ),
              const Text('¡Bienvenido a tu nueva cuenta! Te mostraremos los alrededores.'),
            ],
          ),
        ),
      ),
    );
  }
}
