import 'package:example/led.dart';
import 'package:example/paint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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
  //     return Paint()
  //       ..style = PaintingStyle.fill
  //       ..color = color
  //       ..strokeWidth = active ? 6 : 4
  //       ..isAntiAlias = true;

  List<ValueRange> bedValues = [
    ValueRange(
        start: 20, end: 60, activeTrackColorPaint: fromColor(Colors.red)),
    ValueRange(
        start: 50, end: 120, activeTrackColorPaint: fromColor(Colors.green)),
  ];
  bool bedEnabled = true;
  ValueRange? selected = null;

  LedApi api = LedApi();

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
            onChanged: (value) => onChanged(value),
            enabled: bedEnabled,
            onToggle: (value) => setState(() => bedEnabled = value),
            onSelect: (value) => setState(() => selected = value),
          ),
          RangeSetting(
              rangeAcceptor: (range) => onRangeSet(range),
              rangeUpdated: (range) => setState(() => onRangeUpdated(range)),
              value: selected),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void onRangeSet(ValueRange range) {
    setState(() {
      if (range == selected) {
        selected = null;
      } else {
        bedValues.add(range);
      }
    });
    api.setRanges(bedValues);
  }

  void onRangeUpdated(ValueRange range) {
    api.setRanges(bedValues);
  }

  void onChanged(List<ValueRange> ranges) {
    setState(() => bedValues = ranges);
    api.setRanges(ranges);
  }
}

typedef RangeAcceptor = void Function(ValueRange);

class RangeSetting extends StatefulWidget {
  final RangeAcceptor rangeAcceptor;
  final RangeAcceptor rangeUpdated;
  ValueRange value;
  String text;
  bool edit;

  RangeSetting(
      {super.key,
      required this.rangeAcceptor,
      required this.rangeUpdated,
      ValueRange? value})
      : value = value ??
            ValueRange(
                start: 0,
                end: 40,
                activeTrackColorPaint: fromColor(Colors.orange)),
        text = value == null ? "Add" : "Save",
        edit = value != null;

  @override
  State<StatefulWidget> createState() => RangeSettingState();
}

class RangeSettingState extends State<RangeSetting> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
        child: Column(children: [
      ColorPicker(
          pickerColor: widget.value.activeTrackColorPaint!.color,
          enableAlpha: false,
          onColorChanged: _onColorChange),
      ElevatedButton(
        child: Text(widget.text),
        // color: theme.colorScheme.primary,
        onPressed: () => widget.rangeAcceptor(widget.value),
      )
    ]));
  }

  void _onColorChange(Color c) {
    widget.value.activeTrackColorPaint!.color = c;
    if (widget.edit) {
      widget.rangeUpdated(widget.value);
    }
  }
}

class Strip extends StatelessWidget {
  const Strip({
    required this.values,
    required this.name,
    required this.onChanged,
    required this.onToggle,
    required this.onSelect,
    required this.enabled,
    Key? key,
  }) : super(key: key);

  final List<ValueRange> values;

  final String name;

  final ValueChanged<List<ValueRange>> onChanged;

  final ValueChanged<bool> onToggle;

  final ValueChanged<ValueRange> onSelect;

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
              ],
            ),
          ),
          Container(
              color: Colors.black,
              child: MultiSlider(
                  values: values,
                  onChanged: enabled ? onChanged : null,
                  // valueRangePainterCallback: (range) => range.index % 2 == 1,
                  divisions: null,
                  min: 0,
                  max: 128)),
          const SizedBox(height: 8),
          if (enabled) ...[
            for (int index = 0; index < values.length; index++)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: values[index].activeTrackColorPaint?.color,
                    shadows: const [
                      BoxShadow(
                          blurRadius: 3,
                          spreadRadius: 2,
                          offset: Offset(1, 1.5),
                          color: Colors.black38)
                    ],
                  ),
                  IconButton(
                      onPressed: () => _removeRange(index),
                      constraints: const BoxConstraints.tightFor(width: 32),
                      icon: const Icon(Icons.remove_circle_outline)),
                  IconButton(
                      onPressed: () => _select(index),
                      constraints: const BoxConstraints.tightFor(width: 32),
                      icon: const Icon(Icons.edit)),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '${index + 1}: ${values[index].start.round()} - ${values[index].end.round()}',
                    ),
                  )
                ],
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

  void _removeRange(int index) {
    values.removeAt(index);
    onChanged(values);
  }

  void _select(int index) {
    onSelect(values[index]);
  }
}
