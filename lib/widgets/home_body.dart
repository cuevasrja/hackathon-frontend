import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hackathon_frontend/widgets/customize_event_button.dart';
import 'package:hackathon_frontend/widgets/getting_started_card.dart';
import 'package:hackathon_frontend/widgets/manage_your_events_section.dart';
import 'package:hackathon_frontend/widgets/whats_for_event_section.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: SvgPicture.asset(
                        'lib/assets/icon_logo_clear.svg',
                        height: 50,
                      ),
                    ),
                    Text(
                      '¡Es hora de un plancito!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Text(
                      'Una forma rápida y cómoda de organizar tus salidas.',
                    ),
                  ],
                ),
              ),
              const GettingStartedCard(),
              const WhatsForEventSection(),
              const ManageYourEventsSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const CustomizeEventButton(margin: EdgeInsets.fromLTRB(16, 16, 16, 24)),
      ],
    );
  }
}
