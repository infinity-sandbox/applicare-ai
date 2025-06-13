import 'package:dio/dio.dart';
import 'package:mobile/config/env.dart';

class SpeechService {
  final Dio _dio = Dio();

  Future<String> transcribeAudio(String audioPath) async {
    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        options: Options(headers: {
          'Authorization': 'Bearer ${Env.openAiKey}',
        }),
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(audioPath),
          'model': 'whisper-1',
        }),
      );
      return response.data['text'];
    } catch (e) {
      throw Exception('Transcription failed');
    }
  }
}
