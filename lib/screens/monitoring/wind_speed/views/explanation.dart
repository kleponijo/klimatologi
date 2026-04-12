import 'package:flutter/material.dart';

class WindSpeedExplanation extends StatelessWidget {
  const WindSpeedExplanation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color.fromARGB(255, 232, 240, 245),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Penjelasan Kecepatan Angin",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Kecepatan angin adalah laju gerakan massa udara yang mengalir secara horizontal. Data kecepatan angin penting untuk prediksi cuaca, manajemen rawan angin, perencanaan energi terbarukan (angin), serta membantu dalam pengeringan hasil pertanian. Pengukuran dilakukan dalam satuan km/h.",
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ],
      ),
    );
  }
}
