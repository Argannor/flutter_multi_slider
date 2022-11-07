import 'package:example/time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_slider/flutter_multi_slider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Demo',
        home: MyHomePage(),
      );
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<double> bedValues = [0.1, 0.2, 0.4, 0.5];
  bool bedEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MultiSlider'),
      ),
      body: ListView(
        children: <Widget>[
          Strip(
            name: 'Bed',
            values: bedValues,
            onChanged: (value) => setState(() => bedValues = value),
            enabled: bedEnabled,
            onToggle: (value) => setState(() => bedEnabled = value),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Strip extends StatelessWidget {
  const Strip({
    required this.values,
    required this.name,
    required this.onChanged,
    required this.onToggle,
    required this.enabled,
    Key? key,
  }) : super(key: key);

  final List<double> values;

  final String name;

  final ValueChanged<List<double>> onChanged;

  final ValueChanged<bool> onToggle;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final chartTextFont = TextStyle(fontSize: 12);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 18),
                  ),
                ),
                Switch(value: enabled, onChanged: onToggle),
              ],
            ),
          ),
          MultiSlider(
              values: values,
              onChanged: enabled ? onChanged : null,
              valueRangePainterCallback: (range) => range.index % 2 == 1,
              divisions: null,
              min: 0,
              max: 255),
          const SizedBox(height: 8),
          if (enabled) ...[
            for (int index = 0; index < values.length; index += 2)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  'Light range ${index ~/ 2 + 1} starts at ${values[index].round()} and ends at ${values[index + 1].round()}.',
                ),
              ),
          ] else
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 2),
              child: Text('No lights.'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

final start = Time(hours: 0, minutes: 0);

final end = Time(hours: 24, minutes: 0);

Time lerpTime(double x) => start + (end - start) * x;
