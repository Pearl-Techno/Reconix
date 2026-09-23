import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reconciliation_match.dart';

class AppColors {
  // Brand Palette
  static const Color emeraldDark = Color(0xFF0F382C);
  static const Color emeraldPrimary = Color(0xFF047857);
  static const Color mintAccent = Color(0xFF10B981);
  static const Color kraGold = Color(0xFFD97706);
  static const Color crimsonRisk = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF97316);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Surface & Backgrounds (Dark Mode Slate)
  static const Color darkBg = Color(0xFF0B0F17);
  static const Color darkSidebar = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: AppColors.emeraldPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.mintAccent,
        secondary: AppColors.kraGold,
        surface: AppColors.darkCard,
        error: AppColors.crimsonRisk,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),
    );
  }

  static Color getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.matched:
        return AppColors.mintAccent;
      case MatchStatus.timingLatency:
        return AppColors.infoBlue;
      case MatchStatus.unclaimedInputVat:
        return AppColors.warningOrange;
      case MatchStatus.vaaDisallowanceRisk:
      case MatchStatus.expenseValidationRisk2026:
        return AppColors.crimsonRisk;
      case MatchStatus.amountRateVariance:
        return AppColors.kraGold;
      case MatchStatus.unmatchedEtimsOnly:
      case MatchStatus.unmatchedItaxOnly:
        return Colors.purpleAccent;
    }
  }

  static Color getRiskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.safe:
        return AppColors.mintAccent;
      case RiskLevel.low:
        return AppColors.infoBlue;
      case RiskLevel.medium:
        return AppColors.kraGold;
      case RiskLevel.high:
        return AppColors.warningOrange;
      case RiskLevel.critical:
        return AppColors.crimsonRisk;
    }
  }
}
