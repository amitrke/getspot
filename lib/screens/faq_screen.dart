import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: const <Widget>[
            Text(
              'For Users',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ExpansionTile(
              title: Text('How do I join a group?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'To join a group, you need a group code from the group\'s administrator. Once you have the code, go to the home screen and tap the "Join Group" button.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('How does the wallet work?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Your wallet is used for event fees. When you register, the fee is deducted from your balance. If you need to add funds, please coordinate with your group admin directly (e.g., via cash or bank transfer). The admin can then update your wallet balance in the app.\n\nPlease note: The wallet is for tracking purposes only and does not handle real money.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('Important: Real Money & Refunds'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'This app DOES NOT process or handle real money. The wallet feature is a virtual ledger to help you and your group admin track payments and credits.\n\nAll financial transactions must occur outside of the app. We are not responsible for any real-money disputes or refunds, which must be settled directly between members and their group administrator.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('What does "Waitlisted" mean?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'If an event is full, you can join the waitlist. If a confirmed participant withdraws, the first person on the waitlist is automatically promoted to "Confirmed" status.'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'For Admins',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ExpansionTile(
              title: Text('How do I create a group?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'From the home screen, tap the "Create Group" button. Fill in the group details, and a unique group code will be generated for you to share with your members.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('How do I manage join requests?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'When a user requests to join your group, you will see a notification on the group details screen. You can then approve or deny their request from the "Members" page.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('What is the "Commitment Deadline"?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'The commitment deadline is the last point at which a user can withdraw from an event without a penalty. If they withdraw after this deadline, they may not receive a full refund, depending on whether a waitlisted user takes their spot.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
