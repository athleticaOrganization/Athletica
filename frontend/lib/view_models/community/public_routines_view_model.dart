import 'package:flutter/material.dart';

import '../../models/routine/routine_model.dart';
import '../../repositories/routine/routine_repository.dart';
import '../../core/token_storage.dart';

/// ViewModel para cargar y exponer las rutinas públicas disponibles en la comunidad.
class PublicRoutinesViewModel extends ChangeNotifier {
  final RoutineRepository routineRepository;

  bool isLoading = false;
  String? errorMessage;
  List<RoutineModel> publicRoutines = [];
  int? currentUserId;

  PublicRoutinesViewModel({required this.routineRepository});

  /// Carga todas las rutinas públicas desde el backend.
  Future<void> loadPublicRoutines() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Obtener el ID del usuario actual
      currentUserId = await TokenStorage.getUserId();
      // Obtener rutinas publicas
      publicRoutines = await routineRepository.fetchPublicRoutines();
    } catch (e) {
      errorMessage = 'No se pudieron cargar las rutinas públicas.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refresca la lista sin cambiar la interfaz que la consume.
  Future<void> refresh() => loadPublicRoutines();

  /// Determina si una rutina pertenece al usuario actual.
  bool isOwnRoutine(RoutineModel routine) {
    return currentUserId != null && routine.createdBy == currentUserId;
  }

  /// Sigue al creador de una rutina.
  Future<void> followCreator(int userId) async {
    try {
      await routineRepository.followUser(userId);

      _updateFollowStateForCreator(userId: userId, isFollowing: true);
    } catch (e) {
      errorMessage = 'Error al seguir: $e';
      notifyListeners();
    }
  }

  /// Deja de seguir al creador de una rutina.
  Future<void> unfollowCreator(int userId) async {
    try {
      await routineRepository.unfollowUser(userId);

      _updateFollowStateForCreator(userId: userId, isFollowing: false);
    } catch (e) {
      errorMessage = 'Error al dejar de seguir: $e';
      notifyListeners();
    }
  }

  void _updateFollowStateForCreator({
    required int userId,
    required bool isFollowing,
  }) {
    publicRoutines = publicRoutines
        .map(
          (routine) => routine.createdBy == userId
              ? routine.copyWith(isFollowing: isFollowing)
              : routine,
        )
        .toList();
    notifyListeners();
  }

  /// Calcula las iniciales a partir de un nombre.
  static String getInitials(String name) {
    final parts = name.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
