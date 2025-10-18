import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Contact Us',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            const ListTile(
              leading: Icon(Icons.email),
              title: Text('support@plancito.com'),
            ),
            const ListTile(
              leading: Icon(Icons.phone),
              title: Text('+1 234 567 890'),
            ),
            const SizedBox(height: 32.0),
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            ExpansionTile(
              title: const Text('How do I create a new plan?'),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text('To create a new plan, go to the home screen and tap the "+" button.'),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text('How do I edit my profile?'),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text('To edit your profile, go to the profile screen and tap the "Edit Profile" button.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}