import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Audio Quality',
            style: TextStyle(
              color: Colors.pink,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x0FFFFFFF)),
            ),
            child: Column(
              children: [
                _buildQualityOption(
                  context: context,
                  title: 'Hemat Kuota (Data Saver)',
                  subtitle: 'Kualitas audio standar. Menghemat penggunaan data internet.',
                  isSelected: !audioProvider.isHighQuality,
                  onTap: () => audioProvider.setHighQuality(false),
                ),
                const Divider(color: Color(0x1AFFFFFF), height: 1),
                _buildQualityOption(
                  context: context,
                  title: 'Jernih (High Quality)',
                  subtitle: 'Kualitas audio tertinggi. Menggunakan lebih banyak data (HD Video stream).',
                  isSelected: audioProvider.isHighQuality,
                  onTap: () => audioProvider.setHighQuality(true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'About',
            style: TextStyle(
              color: Colors.pink,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x0FFFFFFF)),
            ),
            child: Column(
              children: [
                Image.asset('assets/public-beat-logo.png', width: 64, height: 64, fit: BoxFit.contain),
                const SizedBox(height: 16),
                const Text(
                  'Public Beat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stream music freely without limits, account logins, or advertisements.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
            height: 1.3,
          ),
        ),
      ),
      trailing: isSelected
          ? const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Colors.pink, size: 28)
          : const Icon(CupertinoIcons.circle, color: Colors.white38, size: 28),
      onTap: onTap,
    );
  }
}
