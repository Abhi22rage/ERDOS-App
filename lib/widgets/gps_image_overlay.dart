import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/breakdown_model.dart';

class GPSImageOverlay extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final BreakdownModel breakdown;
  final bool isDarkMode;
  final double? width;
  final double? height;
  final BoxFit fit;

  const GPSImageOverlay({
    super.key,
    this.imageUrl,
    this.imageFile,
    required this.breakdown,
    required this.isDarkMode,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : assert(imageUrl != null || imageFile != null, 'Must provide either imageUrl or imageFile');

  @override
  Widget build(BuildContext context) {
    final timestamp = DateFormat('MMMM dd, yyyy  HH:mm a').format(breakdown.createdAt);
    
    Widget image;
    if (imageFile != null) {
      image = Image.file(
        imageFile!,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        fit: fit,
      );
    } else {
      image = Image.network(
        imageUrl!,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        fit: fit,
      );
    }
    
    return Stack(
      children: [
        image,
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    breakdown.reportNumber?.split('-').first ?? 'Center Name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (breakdown.locationAddress != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("📍 ", style: TextStyle(fontSize: 10)),
                        Expanded(
                          child: Text(
                            breakdown.locationAddress!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (breakdown.locationLat != null && breakdown.locationLng != null)
                    Text(
                      "🌐 ${breakdown.locationLat!.toStringAsFixed(4)}° N , ${breakdown.locationLng!.toStringAsFixed(4)}° E",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.white.withValues(alpha: 0.6), size: 10),
                      const SizedBox(width: 4),
                      Text(
                        timestamp,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
