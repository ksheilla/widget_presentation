import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SlideTransition Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SlideTransitionDemoPage(),
    );
  }
}

///
/// Real-world use case: a slide-out panel (e.g. filters, notifications)
/// that animates in and out. We demonstrate [position] and [transformHitTests].
class SlideTransitionDemoPage extends StatefulWidget {
  const SlideTransitionDemoPage({super.key});

  @override
  State<SlideTransitionDemoPage> createState() =>
      _SlideTransitionDemoPageState();
}

class _SlideTransitionDemoPageState extends State<SlideTransitionDemoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  // position — Tween begin offset; default left
  String _slideFrom = 'left'; // 'left' | 'right' | 'bottom' | 'top'

  // transformHitTests — hit test at drawn position (true) or layout position (false)
  bool _transformHitTests = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _updateSlideAnimation();
  }

  Offset _getHiddenOffset() {
    switch (_slideFrom) {
      case 'right':
        return const Offset(1.0, 0.0);
      case 'bottom':
        return const Offset(0.0, 1.0);
      case 'top':
        return const Offset(0.0, -1.0);
      case 'left':
      default:
        return const Offset(-1.0, 0.0);
    }
  }

  void _updateSlideAnimation() {
    // position: Animation<Offset> — begin = off-screen, end = on-screen (0,0)
    _slideAnimation = Tween<Offset>(
      begin: _getHiddenOffset(),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePanel() {
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SlideTransition'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          // Controls card (behind)
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'position',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _chip('Left', 'left'),
                          _chip('Right', 'right'),
                          _chip('Bottom', 'bottom'),
                          _chip('Top', 'top'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                            'transformHitTests',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _transformHitTests,
                            onChanged: (bool value) =>
                                setState(() => _transformHitTests = value),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Panel in front
          _buildSlidingPanel(context),
          // Toggle centered on top so it's always tappable
          Center(
            child: FilledButton.tonalIcon(
              onPressed: _togglePanel,
              icon: Icon(_controller.isCompleted ? Icons.close : Icons.menu),
              label: Text(_controller.isCompleted ? 'Hide' : 'Show'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlidingPanel(BuildContext context) {
    final isVertical = _slideFrom == 'top' || _slideFrom == 'bottom';
    final alignment = _slideFrom == 'right'
        ? Alignment.centerRight
        : _slideFrom == 'bottom'
        ? Alignment.bottomCenter
        : _slideFrom == 'top'
        ? Alignment.topCenter
        : Alignment.centerLeft;
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: isVertical ? 1.0 : 0.7,
        heightFactor: isVertical ? 0.4 : 1.0,
        child: SlideTransition(
          position: _slideAnimation,
          transformHitTests: _transformHitTests,
          child: Material(
            elevation: 8,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Panel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Tapped'))),
                    child: const Text('Tap'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String direction) {
    final selected = _slideFrom == direction;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool value) {
        setState(() {
          _slideFrom = direction;
          _updateSlideAnimation();
          _controller.reset();
          _controller.forward();
        });
      },
    );
  }
}

/// Constrains width to a fraction of the parent (Stack doesn't size the panel otherwise).
class FractionallySizedBox extends StatelessWidget {
  const FractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.heightFactor,
    required this.child,
  });

  final double widthFactor;
  final double heightFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SizedBox(
          width: constraints.maxWidth * widthFactor,
          height: constraints.maxHeight * heightFactor,
          child: child,
        );
      },
    );
  }
}
