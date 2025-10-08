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
                      'To join a group, you need a group code from the group\'s administrator. Once you have the code, go to the home screen and tap the "Join Group" button. Your request will be sent to the group admin for approval.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('How do I register for an event?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Open the event from your group\'s event list and tap "Register". If you have sufficient wallet balance and the event isn\'t full, you\'ll be confirmed immediately. If the event is full but has a waitlist, you\'ll be added to the waitlist automatically.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('Can I withdraw from an event after registering?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Yes, you can withdraw from an event by opening the event details and tapping "Withdraw". If you withdraw before the commitment deadline, you\'ll receive a full refund. If you withdraw after the deadline, you\'ll only receive a refund if someone from the waitlist takes your spot.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('How does the wallet work?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Your wallet is used for event fees. When you register, the fee is deducted from your balance. If you need to add funds, please coordinate with your group admin directly (e.g., via cash or bank transfer). The admin can then update your wallet balance in the app.\n\nYou can view your transaction history by tapping on your wallet balance in the group details screen.\n\nPlease note: The wallet is for tracking purposes only and does not handle real money.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('What happens if I don\'t have enough wallet balance?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'If your wallet balance is insufficient for an event fee, you won\'t be able to register. Contact your group admin to add funds to your wallet. Remember to complete your real-money payment to the admin outside the app first.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('How do I view my event history?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'You can view all past and upcoming events in your group by opening the group details screen. Events are sorted by date, with upcoming events shown first. Tap on any event to see full details and participant list.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('What does "Waitlisted" mean?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'If an event is full, you can join the waitlist. If a confirmed participant withdraws, the first person on the waitlist (first-in-first-out order) is automatically promoted to "Confirmed" status. You won\'t be charged until you\'re confirmed.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('Can I leave a group?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Yes, you can leave a group by opening the group details screen and selecting "Leave Group" from the menu. Make sure to settle any outstanding wallet balance with your admin before leaving. Note: You cannot leave if you\'re registered for any upcoming events.'),
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
                      'From the home screen, tap the "Create Group" button. Fill in the group details, and a unique group code will be generated for you to share with your members. You can find the group code in the group details screen.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('How do I create an event?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Open your group details screen and tap the "+" button. Fill in the event details including date, time, location, capacity, fee, and commitment deadline. Once created, members will be able to see and register for the event.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('Can I edit an event after creating it?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'You can edit most event details like description, location, and time. However, you cannot change the capacity or fee once participants have registered, as this could affect fairness and financial tracking. If you need to make major changes, consider canceling the event and creating a new one.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('How do I manage join requests?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'When a user requests to join your group, you will see a notification badge on the group details screen. Tap on "Members" and you\'ll see the "Join Requests" section at the top. Review each request and tap "Approve" or "Deny".'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('How do I add funds to a member\'s wallet?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'After collecting real money from a member outside the app, open the Members screen from your group details. Find the member, tap on their profile, and select "Manage Wallet". Enter the amount to add and include a description (e.g., "Cash payment - Jan 2024"). The transaction will be recorded in their wallet history.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('What happens if someone doesn\'t pay for an event?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'The app prevents registration if a member has insufficient wallet balance. If someone owes money from a past event, you can deduct it from their wallet balance or remove them from the group if necessary. All financial settlements must be handled directly between you and the member.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('How do I send announcements?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'From the group details screen, tap the "Announcements" button. Compose your message and tap "Send". All group members will receive a push notification and can view the announcement in the announcements list.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('Can I remove a member from the group?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Yes, open the Members screen, find the member you want to remove, tap on their profile, and select "Remove from Group". Note: You cannot remove a member who is registered for upcoming events. They must withdraw from all events first, or you must cancel those events.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('What is the "Commitment Deadline"?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'The commitment deadline is the last time before an event when a participant can withdraw and receive a guaranteed full refund. Set this deadline based on when you need to finalize attendance (e.g., 24 hours before the event). After the deadline, participants who withdraw only get refunded if someone from the waitlist takes their spot.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('How do I cancel an event?'),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Open the event details screen and select "Cancel Event" from the menu. All participants will be automatically refunded their fees, and they\'ll receive a notification about the cancellation. Consider sending an announcement explaining the reason for cancellation.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
