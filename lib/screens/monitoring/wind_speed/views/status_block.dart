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

    /// ====== Current Speed bagian kode kecepatan angin ===== ///
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kecepatan Angin",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${currentSpeed.toStringAsFixed(2)} km/h",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),

                /// ==== bagian online offline status tampilan ==== ///
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isOnline ? Colors.green.shade100 : Colors.red.shade100,
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
            const SizedBox(height: 10),
            Text(
              "Update: $formattedTime",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
