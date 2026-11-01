import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

class AdminSettingsTab extends StatelessWidget {
  const AdminSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER
          Row(
            children: [
              const Text(
                'Tizim Umumiy Sozlamalari va Xavfsizlik',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF059669).withValues(alpha: 0.2),
                  ),
                ),
                child: const Text(
                  'O‘RQ-547 Standarti',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Davlat axborot tizimi parametrlari, mustaqil ma’lumotlar bazasi va xavfsizlik protokollari',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),

          // 2. TIZIM VA HUQUQIY IDENTIFIKATSIYA
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shield_rounded, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Davlat Axborot Tizimi Standarti va Huquqiy Maqom',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildConfigRow(
                    'Tizim nomi',
                    'TA’LIM NAZORAT — Alohida Ta’lim Ehtiyojlari Bo‘lgan Bolalar Monitoringi',
                  ),
                  _buildConfigRow(
                    'Versiya va arxitektura',
                    'v2.4.0 Release (Zero Supabase, Fully Offline Relational DB)',
                  ),
                  _buildConfigRow(
                    'Mas’ul idora',
                    'O‘zbekiston Respublikasi Maktabgacha va maktab ta’limi vazirligi',
                  ),
                  _buildConfigRow(
                    'Hududiy boshqarma',
                    'Namangan viloyati Maktabgacha va maktab ta’limi boshqarmasi',
                  ),
                  _buildConfigRow(
                    'Qonunchilikka muvofiqlik',
                    'O‘zbekiston Respublikasi O‘RQ-547 "Shaxsga doir ma’lumotlar to‘g‘risida"gi qonuniga 100% muvofiq',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. MA'LUMOTLAR BAZASI VA SUVERENITET
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.storage_rounded, color: Color(0xFF059669)),
                      SizedBox(width: 8),
                      Text(
                        'Ma’lumotlar Bazasi Suvereniteti (Zero Supabase)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildConfigRow(
                    'Baza saqlash usuli',
                    'SharedPreferences Persistent Storage + In-memory relational indexing',
                  ),
                  _buildConfigRow(
                    'Tashqi bulut (Supabase / Firebase)',
                    'O‘chirilgan (Bolalar shaxsiy anketalari tashqi serverlarga yuborilmaydi)',
                  ),
                  _buildConfigRow(
                    'Tarmoqsiz (Oflayn) ishlash',
                    'To‘liq qo‘llab-quvvatlanadi (Internet yo‘qligida barcha funksiyalar cheklovsiz ishlaydi)',
                  ),
                  _buildConfigRow(
                    'Audit logging',
                    'Barcha ma’muriy amallar, kirishlar va o‘zgarishlar o‘zgarmas yozuvda saqlanadi',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. MONITORING VA CHEGARA PARAMETRLARI
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.tune_rounded, color: Color(0xFF7C3AED)),
                      SizedBox(width: 8),
                      Text(
                        'Monitoring Qoidalari Parametrlari',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildConfigRow(
                    'Oraliq baholash davri (RULE_02)',
                    'Har 60 kunda (Maksimal 60 kundan oshganda ogohlantirish beriladi)',
                  ),
                  _buildConfigRow(
                    'Qoldirilgan darslar chegarasi (RULE_01)',
                    '2 ta va undan ko‘p qoldirilgan mashg‘ulotda darhol signal hosil bo‘ladi',
                  ),
                  _buildConfigRow(
                    'Regressiya xavfi chegarasi (RULE_04)',
                    'Ketma-ket baholashlarda 15% dan ortiq pasayish kuzatilganda signal beriladi',
                  ),
                  _buildConfigRow(
                    'Kuzatuvsiz mashg‘ulot chegarasi (RULE_06)',
                    'Bajarilgan mashg‘ulotga professional xulosa kiritilmasa',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. ADMINISTRATOR HISOBI VA PAROLINI O'ZGARTIRISH
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Administrator Xavfsizlik Profili',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildConfigRow('Administrator F.I.SH', user?.fullName ?? ''),
                  _buildConfigRow('Kirish logini / Pochtasi', user?.email ?? ''),
                  _buildConfigRow('Telefon raqami', user?.phone ?? ''),
                  _buildConfigRow('Roli', user?.role.label ?? ''),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _showChangePasswordDialog(context),
                    icon: const Icon(Icons.password_rounded, size: 16),
                    label: const Text('Administrator Parolini Yangilash'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 260,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Administrator Parolini Yangilash'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Eski parol *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Yangi parol *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yangi parolni takrorlang *',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (newPassCtrl.text.trim().length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yangi parol kamida 6 belgidan iborat bo‘lishi shart.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              if (newPassCtrl.text.trim() != confirmPassCtrl.text.trim()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yangi parollar bir-biriga mos kelmadi.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final res = await auth.changePassword(
                oldPassCtrl.text.trim(),
                newPassCtrl.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] as String),
                    backgroundColor: res['success'] == true
                        ? const Color(0xFF059669)
                        : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }
}
