import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiKey = String.fromEnvironment('RAPIDAPI_KEY');
void main() {
  runApp(const WorkoutEquipmentApp());
}

class WorkoutEquipmentApp extends StatelessWidget {
  const WorkoutEquipmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Spaz',
      theme: ThemeData(
        fontFamily: 'Roboto', // or any system-safe font
        useMaterial3: true, // if using Material3
      ),
      debugShowCheckedModeBanner: false,
      home: const TargetSelectionPage(),
    );
  }
}

class TargetSelectionPage extends StatefulWidget {
  const TargetSelectionPage({super.key});

  @override
  State<TargetSelectionPage> createState() => _TargetSelectionPageState();
}

class _TargetSelectionPageState extends State<TargetSelectionPage> {
  List<String> targets = [];
  String? selectedTarget;
  bool isLoading = true;
  String errorMessage = '';

  final String apiBase = 'https://exercisedb.p.rapidapi.com/';
  final Map<String, String> headers = {
    'X-RapidAPI-Key': apiKey,
    'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
  };

  @override
  void initState() {
    super.initState();
    fetchTargets();
  }

  Future<void> fetchTargets() async {
    try {
      final response = await http.get(Uri.parse('${apiBase}exercises/targetList'), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          targets = List<String>.from(data);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load target list (Status ${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching target list: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🏋️ Workout Spaz',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigoAccent,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Choose a Muscle Group",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          value: selectedTarget,
                          items: targets
                              .map((target) => DropdownMenuItem(
                                    value: target,
                                    child: Text(target.toUpperCase()),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedTarget = value;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Muscle Group',
                          ),
                        ),
                        const SizedBox(height: 36),
                        Center(
                          child: GestureDetector(
                            onTap: selectedTarget == null
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ExerciseSwipePage(target: selectedTarget!),
                                      ),
                                    );
                                  },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: selectedTarget != null ? Colors.blueAccent : Colors.grey,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 52,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class ExerciseSwipePage extends StatefulWidget {
  final String target;

  const ExerciseSwipePage({super.key, required this.target});

  @override
  State<ExerciseSwipePage> createState() => _ExerciseSwipePageState();
}

class _ExerciseSwipePageState extends State<ExerciseSwipePage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? currentExercise;
  bool isLoading = true;
  bool isFetchingNext = false; // NEW
  String errorMessage = '';
  bool isSwiping = false;
  Offset swipeOffset = Offset.zero;

  final String apiBase = 'https://exercisedb.p.rapidapi.com/';
  final Map<String, String> headers = {
    'X-RapidAPI-Key': apiKey,
    'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
  };

  @override
  void initState() {
    super.initState();
    fetchRandomExercise(firstLoad: true);
  }

  Future<void> fetchRandomExercise({bool firstLoad = false}) async {
    if (!firstLoad) {
      setState(() {
        isFetchingNext = true;
      });
    }
    try {
      final response = await http.get(
        Uri.parse('${apiBase}exercises/target/${widget.target}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final random = Random();
          final randomExercise = data[random.nextInt(data.length)];
          setState(() {
            currentExercise = Map<String, dynamic>.from(randomExercise);
            isLoading = false;
            swipeOffset = Offset.zero;
            isFetchingNext = false;
          });
        } else {
          setState(() {
            errorMessage = 'No exercises found for target: ${widget.target}';
            isLoading = false;
            isFetchingNext = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load exercises (Status ${response.statusCode})';
          isLoading = false;
          isFetchingNext = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching exercise: $e';
        isLoading = false;
        isFetchingNext = false;
      });
    }
  }

  void onSwipeLeft() {
    setState(() {
      isSwiping = true;
      swipeOffset = const Offset(-2.0, 0); // Animate left
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        isSwiping = false;
        swipeOffset = Offset.zero;
      });
      fetchRandomExercise();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Workout Spaz ${widget.target.toUpperCase()} Exercises',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigoAccent,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Stack(
                  children: [
                    GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                          onSwipeLeft();
                        }
                      },
                      child: Center(
                        child: AnimatedSlide(
                          offset: swipeOffset,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: isSwiping ? 0.0 : 1.0,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: ExerciseCard(
                                name: currentExercise!['name'] ?? 'Unknown',
                                equipment: currentExercise!['equipment'] ?? 'Unknown Equipment',
                                target: currentExercise!['target'] ?? 'Unknown Target',
                                imageUrl: currentExercise!['gifUrl'] ?? '',
                                onNext: onSwipeLeft,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isFetchingNext)
                      Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class ExerciseCard extends StatelessWidget {
  final String name;
  final String equipment;
  final String target;
  final String imageUrl;
  final VoidCallback onNext;

  const ExerciseCard({
    super.key,
    required this.name,
    required this.equipment,
    required this.target,
    required this.imageUrl,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 250, // ✅ Max height for the GIF
              minHeight: 150, // ✅ Min height for the GIF
              maxWidth: double.infinity,
            ),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.contain, // ✅ Keep the GIF proportions, no crop
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Text('No Image'),
              ),
            ),
          ),
        ),
          Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Equipment: $equipment"),
              Text("Target: $target"),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: onNext,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
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
