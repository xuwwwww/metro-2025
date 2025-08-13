import 'package:flutter/material.dart';

class RideshareSection extends StatelessWidget {
  const RideshareSection({super.key, required this.header, required this.body});

  final Widget header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF3A4A5A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.elliptical(100, 70),
          topRight: Radius.elliptical(100, 70),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 15, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 12),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
