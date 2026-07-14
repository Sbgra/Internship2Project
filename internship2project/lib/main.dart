import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Türkçe tarih formatı için yerelleştirme başlat
  await initializeDateFormatting('tr_TR', null);
  runApp(const App());
}
