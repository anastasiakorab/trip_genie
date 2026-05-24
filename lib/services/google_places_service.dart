import 'package:flutter_dotenv/flutter_dotenv.dart';

final googleApiKey =
    dotenv.env['GOOGLE_API_KEY'] ?? '';