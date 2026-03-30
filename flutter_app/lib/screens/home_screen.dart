import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'generate_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thumbnail AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout())
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Welcome!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('User: ${auth.currentUser?.email ?? ""}',
              style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 40),
            _FeatureCard(
              title: 'Generate Thumbnail',
              subtitle: 'Upload images + describe your idea',
              icon: Icons.auto_awesome,
              color: const Color(0xFF6C63FF),
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const GenerateScreen())),
            ),
            const SizedBox(height: 16),
            _FeatureCard(
              title: 'My History',
              subtitle: 'View past generated thumbnails',
              icon: Icons.history,
              color: const Color(0xFF00BFA5),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title, required this.subtitle,
    required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}