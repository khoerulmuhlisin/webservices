import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mysql1/mysql1.dart';

import 'article.dart'; //modeling of entity article

List<Article> articles = [];

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..post('/articles', _postArticleHandler)
  ..get('/karyawan', _connectSqlHandler);

// Fungsi untuk menghubungkan ke MySQL dan mengambil data pengguna.
Future<Response> _connectSqlHandler(Request request) async {
  var settings = ConnectionSettings(
    host: '127.0.0.1',
    port: 3306,
    user: 'dart2',
    password: 'password',
    db: 'tokoonline',
  );

  var conn = await MySqlConnection.connect(settings);

  var users = await conn.query(
      'SELECT karyawan.nama_karyawan, gaji_karyawan.jumlah_gaji FROM karyawan JOIN gaji_karyawan ON karyawan.id_karyawan = gaji_karyawan.id_karyawan',
      []);

  return Response.ok(users.toString());
}

Future<Response> _postArticleHandler(Request request) async {
  String body = await request.readAsString();

  try {
    Article article = articleFromJson(body);
    articles.add(article);
    return Response.ok(articleToJson(article));
  } catch (e) {
    return Response(400);
  }
}

// Fungsi-fungsi handler lainnya
Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
