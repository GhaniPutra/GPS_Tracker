import 'package:flutter/material.dart';
import '../utils/theme.dart';

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _progressController;
  
  int _selectedTab = 0;

  final List<_QuestCategory> _categories = [
    _QuestCategory(name: 'Harian', icon: Icons.today),
    _QuestCategory(name: 'Mingguan', icon: Icons.calendar_view_week),
    _QuestCategory(name: 'Achieve', icon: Icons.emoji_events),
  ];

  final List<_QuestData> _quests = [
    _QuestData(
      id: 1,
      title: 'Pantau Lokasi',
      description: 'Lacak lokasi perangkat selama 30 menit',
      progress: 0.6,
      xp: 100,
      isCompleted: false,
      category: 0,
      icon: Icons.location_on,
      color: AppColors.primary,
    ),
    _QuestData(
      id: 2,
      title: 'Terhubung',
      description: 'Hubungkan 2 perangkat berbeda',
      progress: 1.0,
      xp: 150,
      isCompleted: true,
      category: 0,
      icon: Icons.bluetooth,
      color: AppColors.secondary,
    ),
    _QuestData(
      id: 3,
      title: 'Eksplorasi',
      description: 'Kunjungi 5 lokasi berbeda',
      progress: 0.4,
      xp: 200,
      isCompleted: false,
      category: 0,
      icon: Icons.explore,
      color: AppColors.accent,
    ),
    _QuestData(
      id: 4,
      title: 'Streak 7 Hari',
      description: 'Buka aplikasi 7 hari berturut-turut',
      progress: 0.85,
      xp: 500,
      isCompleted: false,
      category: 1,
      icon: Icons.local_fire_department,
      color: const Color(0xFFFF6B6B),
    ),
    _QuestData(
      id: 5,
      title: 'Master Tracker',
      description: 'Selesaikan 20 quest',
      progress: 0.25,
      xp: 1000,
      isCompleted: false,
      category: 2,
      icon: Icons.workspace_premium,
      color: const Color(0xFFFFD93D),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [AppColors.darkBackground, Color(0xFF1E293B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(theme),
              
              // XP Card
              _buildXpCard(theme, isDark),
              
              // Category Tabs
              _buildCategoryTabs(theme),
              
              // Quest List
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildQuestList(theme, isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quest',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Selesaikan quest untuk XP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXpCard(ThemeData theme, bool isDark) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppGradients.sunset,
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: const Icon(
                Icons.stars,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total XP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    '2,450',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.full),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '+150',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: _categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final isSelected = _selectedTab == index;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: index < _categories.length - 1 ? AppSpacing.sm : 0),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppGradients.primary : null,
                  color: isSelected ? null : (theme.cardColor).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      category.icon,
                      size: 24,
                      color: isSelected ? Colors.white : theme.iconTheme.color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuestList(ThemeData theme, bool isDark) {
    final filteredQuests = _quests.where((q) => q.category == _selectedTab).toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: filteredQuests.length,
      itemBuilder: (context, index) {
        final quest = filteredQuests[index];
        return _buildQuestCard(quest, theme, isDark, index);
      },
    );
  }

  Widget _buildQuestCard(_QuestData quest, ThemeData theme, bool isDark, int index) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - _progressController.value), 0),
          child: Opacity(
            opacity: _progressController.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          gradient: quest.isCompleted ? AppGradients.secondary : null,
          color: quest.isCompleted ? null : (theme.cardColor).withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: quest.isCompleted 
                ? AppColors.secondary 
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: AppShadows.medium,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [quest.color, quest.color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Icon(
                      quest.isCompleted ? Icons.check_circle : quest.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              quest.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: quest.isCompleted ? Colors.white : null,
                              ),
                            ),
                            if (quest.isCompleted) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                                ),
                                child: const Text(
                                  'Selesai',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          quest.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: quest.isCompleted 
                                ? Colors.white.withOpacity(0.8)
                                : theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // XP Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: quest.isCompleted 
                          ? Colors.white.withOpacity(0.2)
                          : quest.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          quest.isCompleted ? Icons.stars : Icons.add,
                          size: 14,
                          color: quest.isCompleted ? Colors.white : quest.color,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '+${quest.xp}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: quest.isCompleted ? Colors.white : quest.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Progress bar
              if (!quest.isCompleted)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kemajuan',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '${(quest.progress * 100).toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: quest.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppBorderRadius.full),
                      child: LinearProgressIndicator(
                        value: quest.progress,
                        minHeight: 8,
                        backgroundColor: (isDark ? AppColors.darkCard : AppColors.lightCard),
                        valueColor: AlwaysStoppedAnimation<Color>(quest.color),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestCategory {
  final String name;
  final IconData icon;

  _QuestCategory({required this.name, required this.icon});
}

class _QuestData {
  final int id;
  final String title;
  final String description;
  final double progress;
  final int xp;
  final bool isCompleted;
  final int category;
  final IconData icon;
  final Color color;

  _QuestData({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.xp,
    required this.isCompleted,
    required this.category,
    required this.icon,
    required this.color,
  });
}

