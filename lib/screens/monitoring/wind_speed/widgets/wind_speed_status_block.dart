import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WindSpeedStatusBlock extends StatelessWidget {
  final double currentSpeed;
  final bool isOnline;
  final DateTime lastUpdateTime;

  const WindSpeedStatusBlock({
    super.key,
    required this.currentSpeed,
    required this.isOnline,
    required this.lastUpdateTime,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime =
        DateFormat("dd MMM yyyy • HH:mm:ss").format(lastUpdateTime);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${currentSpeed.toStringAsFixed(2)} km/h",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOnline ? "ONLINE" : "OFFLINE",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOnline ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Update: $formattedTime",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
