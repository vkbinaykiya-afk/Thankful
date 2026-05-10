import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.figtree(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading1 => GoogleFonts.figtree(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading2 => GoogleFonts.figtree(
        fontSize: 19,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading3 => GoogleFonts.figtree(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.figtree(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.figtree(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  static TextStyle get journal => GoogleFonts.figtree(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.7,
        color: AppColors.textJournal,
      );

  static TextStyle get caption => GoogleFonts.figtree(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get captionMedium => GoogleFonts.figtree(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get micro => GoogleFonts.figtree(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textTertiary,
      );
}
