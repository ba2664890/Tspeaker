import '../models/user.dart';
import 'api_service.dart';

class SimulationService {
  final ApiService _apiService;

  SimulationService(this._apiService);

  Future<List<Simulation>> getSimulations({
    String? category,
    String? difficulty,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (category != null && category.isNotEmpty) {
      queryParameters['category'] = category;
    }
    if (difficulty != null && difficulty.isNotEmpty) {
      queryParameters['difficulty'] = difficulty;
    }

    final response = await _apiService.get(
      '/simulations/',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    if (response.statusCode == 200) {
      final data = (response.data['data'] ?? const []) as List;
      return data
          .map((item) => Simulation.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Impossible de charger les simulations');
  }

  Future<PracticeSessionLaunch> startSimulation(String simulationId) async {
    final response = await _apiService.post('/simulations/$simulationId/start/');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PracticeSessionLaunch.fromJson(
        response.data as Map<String, dynamic>,
      );
    }

    throw Exception('Impossible de démarrer la simulation');
  }
}
