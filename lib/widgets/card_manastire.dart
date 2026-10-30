// lib/widgets/card_manastire.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/manastire.dart';

class CardManastire extends StatelessWidget {
  final Manastire manastire;
  final bool vizitat;
  final VoidCallback onTap;

  const CardManastire({
    super.key,
    required this.manastire,
    required this.vizitat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: const Color(0xFF1A2D3D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _coloanaDistanta(),
              const SizedBox(width: 12),
              Expanded(child: _coloanaInfo()),
              if (vizitat)
                const Icon(Icons.check_circle, color: Color(0xFF66BB6A), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coloanaDistanta() {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Text(
            manastire.distantaKm != null
                ? manastire.distantaKm! < 10
                    ? '${manastire.distantaKm!.toStringAsFixed(1)}'
                    : '${manastire.distantaKm!.toStringAsFixed(0)}'
                : '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text('km', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          if (manastire.unghi != null)
            _Sageata(unghi: manastire.unghi!)
          else
            const Icon(Icons.location_off, color: Colors.white30, size: 20),
        ],
      ),
    );
  }

  Widget _coloanaInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          manastire.nume,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Text(
              manastire.judet,
              style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 11),
            ),
            const SizedBox(width: 8),
            if (manastire.vietuitori != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, color: Colors.white30, size: 11),
                  const SizedBox(width: 2),
                  Text(
                    '${manastire.vietuitori}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 6),
            ],
            _badge(),
            if (manastire.an != null) ...[
              const SizedBox(width: 8),
              Text(
                '${manastire.an}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ],
        ),
        if (manastire.hram.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              manastire.hram,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _badge() {
    final esteMaici = manastire.tip == 'maici';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: esteMaici
            ? const Color(0xFF4A1505)
            : const Color(0xFF0D3A6B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: esteMaici
              ? const Color(0xFF8B3A20)
              : const Color(0xFF1E6AAD),
          width: 0.5,
        ),
      ),
      child: Text(
        esteMaici ? 'maici' : 'călugări',
        style: TextStyle(
          color: esteMaici ? const Color(0xFFF5C4B3) : const Color(0xFF90CAF9),
          fontSize: 10,
        ),
      ),
    );
  }
}

class _Sageata extends StatelessWidget {
  final double unghi;
  const _Sageata({required this.unghi});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: unghi * pi / 180,
      child: const Icon(Icons.navigation, color: Color(0xFFEF9F27), size: 22),
    );
  }
}
