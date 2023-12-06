import 'package:cgg_attendance/routes/app_routes.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.attendance);
              },
              child: const Card(
                elevation: 3.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Attendance',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () {},
              child: const Card(
                elevation: 3.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Delete User',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
