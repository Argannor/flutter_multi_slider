import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_multi_slider/flutter_multi_slider.dart';

class ValueRange extends Comparable<ValueRange>{
  ValueRange(
      {required this.start,
      required this.end,
      this.activeTrackColorPaint,
      this.inactiveTrackColorPaint});

  double start;
  double end;

  final Paint? activeTrackColorPaint;
  final Paint? inactiveTrackColorPaint;

  double min() => math.min(start, end);

  double max() => math.max(start, end);

  ValueRange apply(DoubleOperator operator) {
    return ValueRange(
        start: operator(this.start),
        end: operator(this.end),
        activeTrackColorPaint: this.activeTrackColorPaint,
        inactiveTrackColorPaint: this.inactiveTrackColorPaint);
  }

  @override
  int compareTo(ValueRange other) {
    return this.min().compareTo(other.min());
  }
}

class RangeIndex {
  final int index;
  final RangeBoundary boundary;

  RangeIndex(this.index, this.boundary);

  double _get(ValueRange range) {
    return boundary == RangeBoundary.START ? range.start : range.end;
  }

  void _set(ValueRange range, double value) {
    boundary == RangeBoundary.START ? range.start = value : range.end = value;
  }

  double get(List<ValueRange> list) => _get(list[index]);

  void set(List<ValueRange> list, double value) => _set(list[index], value);
}

enum RangeBoundary { START, END }

/// Used in [ValueRangePainterCallback] as parameter.
/// Every range between the edges of [MultiSlider] generate an [DrawValueRange].
/// Do NOT be mistaken with discrete intervals made by [divisions]!
class DrawValueRange extends Comparable<DrawValueRange> {
  DrawValueRange(this.start, this.end, this.index, this.isFirst,
      this.isLast, this.activeTrackColorPaint, this.inactiveTrackColorPaint);

  final double start;
  final double end;
  final int index;
  final bool isFirst;
  final bool isLast;

  final Paint activeTrackColorPaint;
  final Paint inactiveTrackColorPaint;

  bool contains(double x) => x >= start && x <= end;

  @override
  int compareTo(DrawValueRange other) {
    throw this.start.compareTo(other.start);
  }
}

typedef ValueRangePainterCallback = bool Function(DrawValueRange valueRange);
typedef DoubleOperator = double Function(double original);

class MultiSlider extends StatefulWidget {
  MultiSlider({
    required this.values,
    required this.onChanged,
    this.max = 1,
    this.min = 0,
    this.onChangeStart,
    this.onChangeEnd,
    this.color,
    this.horizontalPadding = 26.0,
    this.height = 45,
    this.divisions,
    this.valueRangePainterCallback,
    this.allowOverlap = true,
    Key? key,
  })  : assert(divisions == null || divisions > 0),
        assert(max - min >= 0),
        range = max - min,
        super(key: key) {
    final valuesCopy = [...values]..sort();

    if (!this.allowOverlap) {
      for (int index = 0; index < valuesCopy.length; index++) {
        assert(
          valuesCopy[index] == values[index],
          'MultiSlider: values must be in ascending order!',
        );
      }
    }
    assert(
      values.any((range) => range.min() >= min) &&
          values.any((range) => range.max() <= max),
      'MultiSlider: At least one value is outside of min/max boundaries!',
    );
  }

  /// [MultiSlider] maximum value.
  final double max;

  /// [MultiSlider] minimum value.
  final double min;

  /// Difference between [max] and [min]. Must be positive!
  final double range;

  /// [MultiSlider] vertical dimension. Used by [GestureDetector] and [CustomPainter].
  final double height;

  /// Empty space between the [MultiSlider] bar and the end of [GestureDetector] zone.
  final double horizontalPadding;

  /// Bar and indicators active color.
  final Color? color;

  /// List of ordered values which will be changed by user gestures with this widget.
  final List<ValueRange> values;

  /// Callback for every user slide gesture.
  final ValueChanged<List<ValueRange>>? onChanged;

  /// Callback for every time user click on this widget.
  final ValueChanged<List<ValueRange>>? onChangeStart;

  /// Callback for every time user stop click/slide on this widget.
  final ValueChanged<List<ValueRange>>? onChangeEnd;

  /// Number of divisions for discrete Slider.
  final int? divisions;

  /// Allows sliders to overlap
  final bool allowOverlap;

  /// Used to decide how a line between values or the boundaries should be painted.
  /// Returns [bool] and pass an [DrawValueRange] object as parameter.
  final ValueRangePainterCallback? valueRangePainterCallback;

  @override
  _MultiSliderState createState() => _MultiSliderState();
}

class _MultiSliderState extends State<MultiSlider> {
  double? _maxWidth;
  RangeIndex? _selectedInputIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sliderTheme = SliderTheme.of(context);

    final bool isDisabled = widget.onChanged == null || widget.range == 0;

    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        _maxWidth = constraints.maxWidth;
        return GestureDetector(
          child: Container(
            constraints: constraints,
            width: double.infinity,
            height: widget.height,
            child: CustomPaint(
              painter: _MultiSliderPainter(
                valueRangePainterCallback: widget.valueRangePainterCallback ??
                    _defaultDivisionPainterCallback,
                divisions: widget.divisions,
                isDisabled: isDisabled,
                activeTrackColor: widget.color ??
                    sliderTheme.activeTrackColor ??
                    theme.colorScheme.primary,
                inactiveTrackColor: widget.color?.withOpacity(0.24) ??
                    sliderTheme.inactiveTrackColor ??
                    theme.colorScheme.primary.withOpacity(0.24),
                disabledActiveTrackColor:
                    sliderTheme.disabledActiveTrackColor ??
                        theme.colorScheme.onSurface.withOpacity(0.40),
                disabledInactiveTrackColor:
                    sliderTheme.disabledInactiveTrackColor ??
                        theme.colorScheme.onSurface.withOpacity(0.12),
                selectedInputIndex: _selectedInputIndex,
                values: widget.values
                    .map((range) => range.apply(_convertValueToPixelPosition))
                    .toList(),
                horizontalPadding: widget.horizontalPadding,
              ),
            ),
          ),
          onPanStart: isDisabled ? null : _handleOnChangeStart,
          onPanUpdate: isDisabled ? null : _handleOnChanged,
          onPanEnd: isDisabled ? null : _handleOnChangeEnd,
        );
      },
    );
  }

  void _handleOnChangeStart(DragStartDetails details) {
    double valuePosition = _convertPixelPositionToValue(
      details.localPosition.dx,
    );

    RangeIndex index = _findNearestValueIndex(valuePosition);

    setState(() => _selectedInputIndex = index);

    final updatedValues = updateInternalValues(details.localPosition.dx);
    widget.onChanged!(updatedValues);
    if (widget.onChangeStart != null) widget.onChangeStart!(updatedValues);
  }

  void _handleOnChanged(DragUpdateDetails details) {
    widget.onChanged!(updateInternalValues(details.localPosition.dx));
  }

  void _handleOnChangeEnd(DragEndDetails details) {
    setState(() => _selectedInputIndex = null);

    if (widget.onChangeEnd != null) widget.onChangeEnd!(widget.values);
  }

  double _convertValueToPixelPosition(double value) {
    return (value - widget.min) *
            (_maxWidth! - 2 * widget.horizontalPadding) /
            (widget.range) +
        widget.horizontalPadding;
  }

  double _convertPixelPositionToValue(double pixelPosition) {
    final value = (pixelPosition - widget.horizontalPadding) *
            (widget.range) /
            (_maxWidth! - 2 * widget.horizontalPadding) +
        widget.min;

    return value;
  }

  List<ValueRange> updateInternalValues(double xPosition) {
    if (_selectedInputIndex == null) return widget.values;

    List<ValueRange> copiedValues = [...widget.values];

    double convertedPosition = _convertPixelPositionToValue(xPosition);
    convertedPosition = convertedPosition.clamp(
      _calculateInnerBound(),
      _calculateOuterBound(),
    );
    if (widget.divisions != null) {
      convertedPosition = _getDiscreteValue(
        convertedPosition,
        widget.min,
        widget.max,
        widget.divisions!,
      );
    }
    _selectedInputIndex!.set(copiedValues, convertedPosition);

    return copiedValues;
  }

  double _calculateInnerBound() {
    if (widget.allowOverlap) {
      return widget.min;
    }
    return _selectedInputIndex!.index == 0
        ? widget.min
        : widget.values[_selectedInputIndex!.index - 1].end;
  }

  double _calculateOuterBound() {
    if (widget.allowOverlap) {
      return widget.max;
    }
    return _selectedInputIndex!.index == widget.values.length - 1
        ? widget.max
        : widget.values[_selectedInputIndex!.index + 1].start;
  }

  RangeIndex _findNearestValueIndex(double convertedPosition) {
    List<ValueRange> differences = widget.values
        .map((ValueRange value) =>
            value.apply(((x) => (x - convertedPosition).abs())))
        .toList();
    List<ValueRange> sortedDifferences = List.from(differences);
    sortedDifferences.sort((a, b) => a.min().compareTo(b.min()));

    int index = differences.indexOf(sortedDifferences[0]);
    return RangeIndex(
        index,
        sortedDifferences[0].start == sortedDifferences[0].min()
            ? RangeBoundary.START
            : RangeBoundary.END);
  }

  bool _defaultDivisionPainterCallback(DrawValueRange division) =>
      !division.isLast;
}

class _MultiSliderPainter extends CustomPainter {
  final List<ValueRange> values;
  final RangeIndex? selectedInputIndex;
  final double horizontalPadding;
  final Paint activeTrackColorPaint;
  final Paint bigCircleColorPaint;
  final Paint inactiveTrackColorPaint;
  final int? divisions;
  final ValueRangePainterCallback valueRangePainterCallback;

  _MultiSliderPainter({
    required bool isDisabled,
    required Color activeTrackColor,
    required Color inactiveTrackColor,
    required Color disabledActiveTrackColor,
    required Color disabledInactiveTrackColor,
    required this.values,
    required this.selectedInputIndex,
    required this.horizontalPadding,
    required this.divisions,
    required this.valueRangePainterCallback,
  })  : activeTrackColorPaint = _paintFromColor(
          isDisabled ? disabledActiveTrackColor : activeTrackColor,
          true,
        ),
        inactiveTrackColorPaint = _paintFromColor(
          isDisabled ? disabledInactiveTrackColor : inactiveTrackColor,
        ),
        bigCircleColorPaint = _paintFromColor(
          activeTrackColor.withOpacity(0.20),
        );

  @override
  void paint(Canvas canvas, Size size) {
    final double halfHeight = size.height / 2;
    final canvasStart = horizontalPadding;
    final canvasEnd = size.width - horizontalPadding;

    List<DrawValueRange> _makeRanges(
      List<ValueRange> innerValues,
      double start,
      double end,
    ) {
      int index = 0;
      Paint sliderPaint = _paintFromColor(Colors.black, true);
      return [
        DrawValueRange(start, end, index, index == 0, true, sliderPaint, sliderPaint),
        ...innerValues
            .map((e) => e.apply((original) => divisions == null ? original : _getDiscreteValue(original, start, end, divisions!)))
            .map((e) => DrawValueRange(e.start, e.end, index++, index == 0, false, e.activeTrackColorPaint != null ? e.activeTrackColorPaint! : activeTrackColorPaint,  e.inactiveTrackColorPaint != null ? e.inactiveTrackColorPaint! : inactiveTrackColorPaint)),

      ];
    }

    final valueRanges = _makeRanges(values, canvasStart, canvasEnd);
    // canvas.drawRect(size, _paintFromColor(Colors.black));
    // canvas.drawColor(Colors.black, BlendMode.src);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(valueRanges.first.start, halfHeight),
        radius: valueRangePainterCallback(valueRanges.first) ? 3 : 2,
      ),
      math.pi / 2,
      math.pi,
      true,
      valueRangePainterCallback(valueRanges.first)
          ? activeTrackColorPaint
          : inactiveTrackColorPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(valueRanges.last.end, halfHeight),
        radius: valueRangePainterCallback(valueRanges.last) ? 3 : 2,
      ),
      -math.pi / 2,
      math.pi,
      true,
      valueRangePainterCallback(valueRanges.last)
          ? activeTrackColorPaint
          : inactiveTrackColorPaint,
    );

    for (DrawValueRange valueRange in valueRanges) {
      canvas.drawLine(
        Offset(valueRange.start, halfHeight),
        Offset(valueRange.end, halfHeight),
        valueRangePainterCallback(valueRange)
            ? valueRange.activeTrackColorPaint
            : valueRange.inactiveTrackColorPaint,
      );
    }

    if (divisions != null) {
      final divisionsList = List<double>.generate(
          divisions! + 1,
          (index) =>
              canvasStart + index * (canvasEnd - canvasStart) / divisions!);

      for (double x in divisionsList) {
        final valueRange = valueRanges.firstWhere(
          (valueRange) => valueRange.contains(x),
        );

        canvas.drawCircle(
          Offset(x, halfHeight),
          1,
          _paintFromColor(valueRangePainterCallback(valueRange)
              ? Colors.white.withOpacity(0.5)
              : activeTrackColorPaint.color.withOpacity(0.5)),
        );
      }
    }

    for (RangeBoundary b in RangeBoundary.values) {
      for (int i = 0; i < values.length; i++) {
        double x = b == RangeBoundary.START ? values[i].start : values[i].end;
        x = divisions == null
            ? x
            : _getDiscreteValue(x, canvasStart, canvasEnd, divisions!);

        canvas.drawCircle(
          Offset(x, halfHeight),
          10,
          _paintFromColor(Colors.white),
        );

        canvas.drawCircle(
          Offset(x, halfHeight),
          10,
          activeTrackColorPaint,
        );

        if (selectedInputIndex == i)
          canvas.drawCircle(
            Offset(x, halfHeight),
            22.5,
            bigCircleColorPaint,
          );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  static Paint _paintFromColor(Color color, [bool active = false]) {
    return Paint()
      ..style = PaintingStyle.fill
      ..color = color
      ..strokeWidth = active ? 6 : 4
      ..isAntiAlias = true;
  }
}

double _getDiscreteValue(
  double value,
  double start,
  double end,
  int divisions,
) {
  final k = (end - start) / divisions;
  return start + ((value - start) / k).roundToDouble() * k;
}
