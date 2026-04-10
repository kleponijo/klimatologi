import 'package:flutter/material.dart';

class WindSpeedExplanation extends StatelessWidget {
  const WindSpeedExplanation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Penjelasan Kecepatan Angin",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Kecepatan angin adalah laju gerakan massa udara yang mengalir secara horizontal. Data kecepatan angin penting untuk prediksi cuaca, manajemen rawan angin, perencanaan energi terbarukan (angin), serta membantu dalam pengeringan hasil pertanian. Pengukuran dilakukan dalam satuan km/h.",
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
