import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

void main() {
  runApp(const AppYahve());
}

class AppYahve extends StatelessWidget {
  const AppYahve({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AppYahve',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF28C7FA),
          brightness: Brightness.light,
        ),
        fontFamily: 'Arial',
      ),
      home: const MathAdventureScreen(),
    );
  }
}

enum MathMode {
  addition('Sumar', '+', Icons.add_circle_rounded, Color(0xFF28C7FA)),
  subtraction('Restar', '-', Icons.remove_circle_rounded, Color(0xFFFFB84D)),
  multiplication('Multiplicar', 'x', Icons.close_rounded, Color(0xFF7DD56F));

  const MathMode(this.label, this.symbol, this.icon, this.color);

  final String label;
  final String symbol;
  final IconData icon;
  final Color color;
}

class Question {
  const Question({
    required this.left,
    required this.right,
    required this.answer,
    required this.options,
    required this.mode,
  });

  final int left;
  final int right;
  final int answer;
  final List<int> options;
  final MathMode mode;
}

class MathAdventureScreen extends StatefulWidget {
  const MathAdventureScreen({super.key});

  @override
  State<MathAdventureScreen> createState() => _MathAdventureScreenState();
}

class _MathAdventureScreenState extends State<MathAdventureScreen>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  late AnimationController _pulseController;

  MathMode _mode = MathMode.addition;
  late Question _question;
  int _score = 0;
  int _streak = 0;
  int _level = 1;
  int _hearts = 3;
  int? _selectedAnswer;
  bool _answered = false;
  String _message = 'Elige una respuesta y gana estrellas.';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.96,
      upperBound: 1.04,
    )..repeat(reverse: true);
    _question = _makeQuestion();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Question _makeQuestion() {
    final int cap = min(12, 5 + _level * 2);
    int left = _random.nextInt(cap) + 1;
    int right = _random.nextInt(cap) + 1;
    int answer;

    if (_mode == MathMode.subtraction && right > left) {
      final int temp = left;
      left = right;
      right = temp;
    }

    switch (_mode) {
      case MathMode.addition:
        answer = left + right;
      case MathMode.subtraction:
        answer = left - right;
      case MathMode.multiplication:
        left = _random.nextInt(min(10, 3 + _level)) + 1;
        right = _random.nextInt(min(10, 3 + _level)) + 1;
        answer = left * right;
    }

    final Set<int> options = {answer};
    while (options.length < 4) {
      final int offset = _random.nextInt(9) - 4;
      final int candidate = max(0, answer + offset + _random.nextInt(3));
      options.add(candidate);
    }

    return Question(
      left: left,
      right: right,
      answer: answer,
      options: options.toList()..shuffle(_random),
      mode: _mode,
    );
  }

  void _changeMode(MathMode mode) {
    setState(() {
      _mode = mode;
      _selectedAnswer = null;
      _answered = false;
      _message = 'Nuevo mundo desbloqueado: ${mode.label}.';
      _question = _makeQuestion();
    });
  }

  void _chooseAnswer(int value) {
    if (_answered) return;

    final bool isCorrect = value == _question.answer;
    setState(() {
      _selectedAnswer = value;
      _answered = true;

      if (isCorrect) {
        _score += 10 + _streak;
        _streak++;
        if (_streak % 4 == 0) _level++;
        _message = _streak >= 3
            ? 'Racha brillante: $_streak aciertos.'
            : 'Muy bien. Tu cerebro esta entrenando.';
      } else {
        _streak = 0;
        _hearts = max(0, _hearts - 1);
        _message = _hearts == 0
            ? 'Respira. Reiniciamos corazones y seguimos.'
            : 'Casi. Mira la operacion y prueba otra.';
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_hearts == 0) {
        _hearts = 3;
        _level = max(1, _level - 1);
      }
      _selectedAnswer = null;
      _answered = false;
      _question = _makeQuestion();
      _message = 'Vamos por otra aventura.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8FE9FF),
              Color(0xFFFFE082),
              Color(0xFFFF8AB3),
              Color(0xFF8CE99A),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const _FloatingBubble(size: 120, top: 34, left: -34),
              const _FloatingBubble(size: 88, top: 92, right: 24),
              const _FloatingBubble(size: 150, bottom: -38, right: -42),
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 720;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Header(score: _score, hearts: _hearts),
                              const SizedBox(height: 14),
                              _ModeSelector(
                                currentMode: _mode,
                                onModeSelected: _changeMode,
                              ),
                              const SizedBox(height: 14),
                              _QuestionCard(
                                question: _question,
                                level: _level,
                                streak: _streak,
                                pulse: _pulseController,
                              ),
                              const SizedBox(height: 14),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _question.options.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isWide ? 4 : 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: isWide ? 1.35 : 1.75,
                                    ),
                                itemBuilder: (context, index) {
                                  final int option = _question.options[index];
                                  return _AnswerButton(
                                    value: option,
                                    selectedAnswer: _selectedAnswer,
                                    correctAnswer: _question.answer,
                                    answered: _answered,
                                    onTap: () => _chooseAnswer(option),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              _CoachPanel(
                                message: _message,
                                answered: _answered,
                                onNext: _nextQuestion,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.score, required this.hearts});

  final int score;
  final int hearts;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFFFB300),
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AppYahve',
                  style: TextStyle(
                    color: Color(0xFF123047),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Mision matematica',
                  style: TextStyle(
                    color: Color(0xFF33566E),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _StatPill(icon: Icons.star_rounded, label: '$score'),
          const SizedBox(width: 8),
          _StatPill(icon: Icons.favorite_rounded, label: '$hearts'),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.currentMode,
    required this.onModeSelected,
  });

  final MathMode currentMode;
  final ValueChanged<MathMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MathMode.values.map((mode) {
        final bool selected = mode == currentMode;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 74,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.82)
                    : Colors.white.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: mode.color.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onModeSelected(mode),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(mode.icon, color: mode.color, size: 28),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        mode.label,
                        style: const TextStyle(
                          color: Color(0xFF123047),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.level,
    required this.streak,
    required this.pulse,
  });

  final Question question;
  final int level;
  final int streak;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _MiniBadge(label: 'Nivel $level'),
              const Spacer(),
              _MiniBadge(label: 'Racha $streak'),
            ],
          ),
          const SizedBox(height: 18),
          ScaleTransition(
            scale: pulse,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: question.mode.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
              ),
              child: Text(
                '${question.left} ${question.mode.symbol} ${question.right} = ?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Toca la respuesta correcta para cargar tu cohete de estrellas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF33566E),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.value,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.answered,
    required this.onTap,
  });

  final int value;
  final int? selectedAnswer;
  final int correctAnswer;
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedAnswer == value;
    final bool isCorrect = value == correctAnswer;
    final Color color = answered && isCorrect
        ? const Color(0xFF22C55E)
        : answered && isSelected
        ? const Color(0xFFFF4D6D)
        : const Color(0xFFffffff);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: color.withValues(alpha: answered ? 0.9 : 0.62),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
              color: answered && (isSelected || isCorrect)
                  ? Colors.white
                  : const Color(0xFF123047),
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachPanel extends StatelessWidget {
  const _CoachPanel({
    required this.message,
    required this.answered,
    required this.onNext,
  });

  final String message;
  final bool answered;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(Icons.psychology_alt_rounded, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF123047),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: answered ? onNext : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF123047),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFB300), size: 20),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF123047),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBubble extends StatelessWidget {
  const _FloatingBubble({
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final double size;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
        ),
      ),
    );
  }
}
