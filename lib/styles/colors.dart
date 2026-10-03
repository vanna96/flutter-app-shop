import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  //One instance, needs factory
  static AppColors? _instance;
  factory AppColors() => _instance ??= AppColors._();

  AppColors._();

  static const primaryColor = Color(0xFFFF762D);
  static const primaryHover = Color(0xFFF06518);
  static const primaryLight = Color(0xFFFFF1E8);
  static const primarySubtle = Color(0x14FF762D);
  static const background = Color(0xFFF8FAFC);
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const success = Color(0xFF10B981);
  static const darkGrey = Color(0xff7C7C7C);
  static const trGrey = Color(0x1D9E9ED3);
}
