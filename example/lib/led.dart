import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_multi_slider/flutter_multi_slider.dart';
import 'package:http/http.dart' as http;

class LedApi {
  String host = "http://10.0.2.2:8081";
  int pixelCount = 128;

  Timer? _debounce;

  void setRanges(List<ValueRange> ranges) {
    if(_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 10), () {
      compute(_setRanges, ranges);
    });
  }

  void _setRanges(List<ValueRange> ranges) async {
    List<int> colors = List.filled(128, 0);
    int r, g, b = 0;
    int rc, gc, bc = 0;
    for (var range in ranges) {
      int start = range.start.round();
      int end = range.end.round();
      start = clamp(start, 0, pixelCount - 1);
      end = clamp(end, 0, pixelCount - 1);
      Color color = range.activeTrackColorPaint!.color;
      r = color.red & 0xFF;
      g = color.green & 0xFF;
      b = color.blue & 0xFF;
      for (var i = start; i < end; i++) {
        rc = (colors[i] & 0xFF0000) >> 16;
        gc = (colors[i] & 0x00FF00) >> 8;
        bc = (colors[i] & 0x0000FF);
        colors[i] = clamp(r + rc, 0, 0xFF) << 16 |
            clamp(g + gc, 0, 0xFF) << 8 |
            clamp(b + bc, 0, 0xFF);
      }
    }
    SetColorsRequest request = SetColorsRequest(colors);
    var response = await http.put(Uri.parse("$host/properties/colors"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request));
    if (response.statusCode != 200) {
      print(response.statusCode);
      print(response.body);
      print("well fuck");
    }
  }


}

class SetColorsRequest {
  List<int> colors;

  SetColorsRequest(this.colors);

  Map<String, dynamic> toJson() => {'colors': colors};
}

int clamp(int value, int min, int max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}
