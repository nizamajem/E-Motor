import 'package:flutter/material.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    this.description = '',
    required this.imageAsset,
    this.primary = const Color(0xFF2C7BFE),
    this.secondary = const Color(0xFF9CC9FF),
    this.tagline,
  });

  final String title;
  final String subtitle;
  final String description;
  final String imageAsset;
  final Color primary;
  final Color secondary;
  final String? tagline;
}
