import 'package:flutter/material.dart';

import '../../models/routine/routine_model.dart';
import '../../repositories/routine/routine_repository.dart';

/// ViewModel para cargar y exponer las rutinas públicas disponibles en la comunidad.
class PublicRoutinesViewModel extends ChangeNotifier {
  final RoutineRepository routineRepository;

  bool isLoading = false;
  String? errorMessage;
  List<RoutineModel> publicRoutines = [];

  PublicRoutinesViewModel({required this.routineRepository});

  /// Carga todas las rutinas públicas desde el backend.
  Future<void> loadPublicRoutines() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
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

  /// Calcula las iniciales a partir de un nombre.
  static String getInitials(String name) {
    final parts = name.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
