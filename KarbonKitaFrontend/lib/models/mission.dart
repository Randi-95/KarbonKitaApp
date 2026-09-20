import 'package:flutter/material.dart';

/// Mission model dari API response.
/// Backend MissionResource: id, title, description, category, xp_reward, points_reward, icon
class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.xpReward,
    required this.pointsReward,
    required this.icon,
  });

  final int id;
  final String title;
  final String description;
  final String category; // 'mobility' | 'waste' | 'quiz'
  final int xpReward;
  final int pointsReward;
  final String icon;

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'mobility',
      xpReward: (json['xp_reward'] as num? ?? 0).toInt(),
      pointsReward: (json['points_reward'] as num? ?? 0).toInt(),
      icon: json['icon'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'xp_reward': xpReward,
    'points_reward': pointsReward,
    'icon': icon,
  };

  /// Helper untuk mapping category ke icon Flutter
  IconData get categoryIcon {
    switch (category) {
      case 'mobility':
        return Icons.pedal_bike;
      case 'waste':
        return Icons.recycling;
      case 'quiz':
        return Icons.help_outline;
      default:
        return Icons.assignment;
    }
  }

  /// Helper untuk mapping category ke color
  Color get categoryColor {
    switch (category) {
      case 'mobility':
        return Colors.green;
      case 'waste':
        return Colors.green;
      case 'quiz':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  /// Helper untuk mapping category ke label Indonesia
  String get categoryLabel {
    switch (category) {
      case 'mobility':
        return 'Mobilitas';
      case 'waste':
        return 'Sampah';
      case 'quiz':
        return 'Kuis';
      default:
        return category;
    }
  }

  /// Helper untuk background color icon
  Color get iconBgColor {
    switch (category) {
      case 'mobility':
        return const Color(0xFFE8F5E9);
      case 'waste':
        return const Color(0xFFE8F5E9);
      case 'quiz':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFE3F2FD);
    }
  }
}
