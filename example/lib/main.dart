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
BlendMode mode = BlendMode.plus;
class _MyHomePageState extends State<MyHomePage> {
  //     return Paint()
  //       ..style = PaintingStyle.fill
  //       ..color = color
  //       ..strokeWidth = active ? 6 : 4
  //       ..isAntiAlias = true;

  List<ValueRange> bedValues = [
    ValueRange(
        start: 20,
        end: 120,
        activeTrackColorPaint: Paint()
          ..color = const Color.fromARGB(255, 255, 0, 0)
          ..strokeWidth = 6
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..blendMode = mode
    ),
    ValueRange(
        start: 90,
        end: 220,
        activeTrackColorPaint: Paint()
          ..color = const Color.fromARGB(255, 0, 255, 0)
          ..strokeWidth = 6
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..blendMode = mode
    ),
  ];
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

  final List<ValueRange> values;

  final String name;

  final ValueChanged<List<ValueRange>> onChanged;

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
          Container(color: Colors.black, child: MultiSlider(
              values: values,
              onChanged: enabled ? onChanged : null,
              // valueRangePainterCallback: (range) => range.index % 2 == 1,
              divisions: null,
              min: 0,
              max: 255)),
          const SizedBox(height: 8),
          if (enabled) ...[
            for (int index = 0; index < values.length; index++)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  'Light range ${index + 1} starts at ${values[index].start.round()} and ends at ${values[index].end.round()}.',
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

