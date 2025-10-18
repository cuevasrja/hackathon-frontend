import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hackathon_frontend/widgets/customize_diet_button.dart';
import 'package:hackathon_frontend/widgets/getting_started_card.dart';
import 'package:hackathon_frontend/widgets/manage_your_meals_section.dart';
import 'package:hackathon_frontend/widgets/whats_for_lunch_section.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SvgPicture.asset('lib/assets/icon_logo_clear.svg', height: 50),
              Text(
                'It\'s time to eat!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Text('Fast and convenient way to eat right'),
            ],
          ),
        ),
        const GettingStartedCard(),
        const WhatsForLunchSection(),
        const ManageYourMealsSection(),
        const CustomizeDietButton(),
      ],
    );
  }
}
