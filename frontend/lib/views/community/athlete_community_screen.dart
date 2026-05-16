import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/api_config.dart';
import '../../models/routine/routine_model.dart';
import '../../repositories/routine/routine_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/community/public_routines_view_model.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => CommunityScreenState();
}

class CommunityScreenState extends State<CommunityScreen> {
  late PublicRoutinesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final repository = RoutineRepository(baseUrl: ApiConfig.baseUrl);
    _viewModel = PublicRoutinesViewModel(routineRepository: repository);
    _viewModel.loadPublicRoutines();
  }

  Future<void> refresh() async {
    return _viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom + 140;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Consumer<PublicRoutinesViewModel>(
            builder: (context, viewModel, _) {
              return RefreshIndicator(
                onRefresh: viewModel.refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: _CommunityHeader()),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        bottomInset,
                      ),
                      sliver: _buildBody(viewModel),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(PublicRoutinesViewModel viewModel) {
    if (viewModel.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (viewModel.errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            viewModel.errorMessage!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText1,
          ),
        ),
      );
    }

    if (viewModel.publicRoutines.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'Todavía no hay rutinas públicas.',
            style: AppTextStyles.bodyText1,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final routine = viewModel.publicRoutines[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _PublicRoutineCard(
            routine: routine,
            onTapTitle: () => _showRoutineDetails(context, routine),
            routineIndex: index.toInt(),
            viewModel: viewModel,
          ),
        );
      }, childCount: viewModel.publicRoutines.length),
    );
  }

  void _showRoutineDetails(BuildContext context, RoutineModel routine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final description = routine.description.trim();
        final hasDescription = description.isNotEmpty;

        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.78,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.78),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: AppRadius.cardLarge,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              routine.title,
                              style: AppTextStyles.screenTitle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              routine.creatorName != null
                                  ? '${routine.creatorName} creó nueva rutina'
                                  : 'Creador no disponible',
                              style: AppTextStyles.sectionSubtitle.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _InfoChip(
                            icon: Icons.category_rounded,
                            label: routine.category,
                          ),
                          _InfoChip(
                            icon: Icons.speed_rounded,
                            label: routine.difficulty,
                          ),
                          _InfoChip(
                            icon: Icons.fitness_center_rounded,
                            label: '${routine.exercises.length} ejercicios',
                          ),
                        ],
                      ),
                      if (hasDescription) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _SectionTitle('Descripción'),
                        const SizedBox(height: AppSpacing.sm),
                        Text(description, style: AppTextStyles.bodyText1),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle('Ejercicios'),
                      const SizedBox(height: AppSpacing.sm),
                      if (routine.exercises.isEmpty)
                        const _EmptyDetailBox(text: 'Sin ejercicios asignados')
                      else
                        ...routine.exercises.map(
                          (exercise) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _ExerciseDetailTile(exercise: exercise),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader();
  static const String _communityText = "COMUNIDAD";
  static const String _subtitlecCommunityText =
      "EXPLORA RUTINAS PÚBLICAS COMPARTIDAS POR OTROS USUARIOS";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _communityText,
                  style: AppTextStyles.fitnessDisplay.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitlecCommunityText,
                  style: AppTextStyles.fitnessCaption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicRoutineCard extends StatelessWidget {
  final RoutineModel routine;
  final VoidCallback onTapTitle;
  final int routineIndex;
  final PublicRoutinesViewModel viewModel;

  const _PublicRoutineCard({
    required this.routine,
    required this.onTapTitle,
    required this.routineIndex,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final creatorName = routine.creatorName ?? 'Usuario';
    final initials = PublicRoutinesViewModel.getInitials(creatorName);
    final isOwnPost = viewModel.isOwnRoutine(routine);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AuthorAvatar(initials: initials),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(creatorName, style: AppTextStyles.bodyText1),
                    Text('creó nueva rutina', style: AppTextStyles.bentoUnit),
                  ],
                ),
              ),
              // Botón de Seguir/Siguiendo - solo si no es el post del usuario actual
              if (!isOwnPost)
                _FollowButton(
                  isFollowing: routine.isFollowing ?? false,
                  onFollow: () => viewModel.followCreator(
                    routine.createdBy!,
                    routineIndex,
                  ),
                  onUnfollow: () => viewModel.unfollowCreator(
                    routine.createdBy!,
                    routineIndex,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: onTapTitle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryLight,
                    AppColors.primaryLight.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.card,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.fitness_center_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      routine.title,
                      style: AppTextStyles.bodyText1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  AUTHOR AVATAR
// ─────────────────────────────────────────────
class _AuthorAvatar extends StatelessWidget {
  final String initials;

  const _AuthorAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.tagBackground,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.bentoUnit.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.chip,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.bentoUnit),
        ],
      ),
    );
  }
}

class _EmptyDetailBox extends StatelessWidget {
  final String text;

  const _EmptyDetailBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: AppTextStyles.bodyText1),
    );
  }
}

class _ExerciseDetailTile extends StatelessWidget {
  final dynamic exercise;

  const _ExerciseDetailTile({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.tagBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${exercise.order}',
                style: AppTextStyles.bentoUnit.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(exercise.exercise.name, style: AppTextStyles.bodyText1),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FOLLOW BUTTON
// ─────────────────────────────────────────────
class _FollowButton extends StatefulWidget {
  final bool isFollowing;
  final Future<void> Function() onFollow;
  final Future<void> Function() onUnfollow;

  const _FollowButton({
    required this.isFollowing,
    required this.onFollow,
    required this.onUnfollow,
  });

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  late bool _isFollowing;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
  }

  void _handleFollowTap() async {
    setState(() => _isLoading = true);
    try {
      if (_isFollowing) {
        await widget.onUnfollow();
      } else {
        await widget.onFollow();
      }
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      // Error se maneja en el ViewModel
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleFollowTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFollowing ? AppColors.surface : AppColors.primary,
          foregroundColor: _isFollowing ? AppColors.primary : Colors.white,
          side: _isFollowing 
              ? const BorderSide(color: AppColors.primary)
              : BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              )
            : Text(
                _isFollowing ? 'Siguiendo' : 'Seguir',
                style: AppTextStyles.bentoUnit,
              ),
      ),
    );
  }
}
