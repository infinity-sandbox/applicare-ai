import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get baseUrl => dotenv.get('BASE_URL');
  static String get openAiKey => dotenv.get('OPENAI_API_KEY');
}
