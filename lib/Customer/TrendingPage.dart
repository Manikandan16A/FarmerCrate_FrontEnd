import 'package:flutter/material.dart';
import 'customerhomepage.dart';

class TrendingPage extends StatelessWidget {
  final String? token;
  const TrendingPage({Key? key, this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trending This Week'), backgroundColor: Colors.green[600]),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: 20,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.green[100], child: Icon(Icons.local_grocery_store, color: Colors.green[700])),
                      title: Text('Trending Item ${index+1}'),
                      subtitle: Text('Popular this week'),
                      trailing: Text('₹${(20+index)*5}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
