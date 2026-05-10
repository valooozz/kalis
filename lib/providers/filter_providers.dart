import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/figure_model.dart';

// null = pas de filtre, sinon la couleur sélectionnée
final colorFilterProvider = StateProvider<FigureColor?>((ref) => null);
