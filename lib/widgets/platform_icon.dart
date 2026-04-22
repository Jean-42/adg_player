import 'package:flutter/material.dart';
import '../models/queue_item.dart';
import '../theme.dart';

class PlatformIcon extends StatelessWidget {
  final MediaType type;
  final double size;

  const PlatformIcon({super.key, required this.type, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Icon(_icon(), color: _color(), size: size);
  }

  IconData _icon() {
    switch (type) {
      case MediaType.youtube:     return Icons.smart_display;
      case MediaType.vimeo:       return Icons.play_circle_filled;
      case MediaType.dailymotion: return Icons.play_arrow;
      case MediaType.facebook:    return Icons.thumb_up;
      case MediaType.instagram:   return Icons.camera_alt;
      case MediaType.radio:       return Icons.radio;
      case MediaType.local:       return Icons.folder_open;
      case MediaType.direct:      return Icons.link;
    }
  }

  Color _color() {
    switch (type) {
      case MediaType.youtube:     return AppColors.youtube;
      case MediaType.vimeo:       return AppColors.vimeo;
      case MediaType.dailymotion: return AppColors.dailymotion;
      case MediaType.facebook:    return AppColors.facebook;
      case MediaType.instagram:   return AppColors.instagram;
      case MediaType.radio:       return AppColors.green;
      case MediaType.local:       return AppColors.yellow;
      case MediaType.direct:      return AppColors.green;
    }
  }
}
