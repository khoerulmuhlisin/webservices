import 'dart:convert';
import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:intl/intl.dart';
import 'karyawan.dart';

class Controller {
  /*SQL Connection*/
  Future<MySqlConnection> connectSql() async {
    var setting = ConnectionSettings(
        host: '127.0.0.1',
        port: 3306,
        user: 'dart2',
        password: 'password',
        db: 'tokoonline');
    var cn = await MySqlConnection.connect(setting);
    return cn;
  }

  /*USER -> CRUD*/
  Future<Response> getUserData(Request request) async {
    var conn = await connectSql();
    var sql = "SELECT * FROM USER";
    var user = await conn.query(sql, []);

    var response = _responseSuccessMsg(user.toString());
    return Response.ok(response.toString());
  }

  Future<Response> getUserDataWithAuth(Request request) async {
    final isValidRequest = await _isValidRequestHeader(request);
    if (!isValidRequest) {
      var response = _responseErrorMsg('Invalid Token');
      return Response.forbidden(jsonEncode(response));
    }

    var conn = await connectSql();
    var sql = "SELECT * FROM USER";
    var data = await conn.query(sql, []);

    // ignore: prefer_collection_literals
    Map<String, dynamic> karyawan = Map<String, dynamic>();

    for (var row in data) {
      karyawan["id_karyawan"] = row["id_user"];
      karyawan["nama_karyawan"] = row["nama_karyawan"];
      karyawan["jabatan"] = row["jabatan"];
      karyawan["gaji"] = row["gaji"];
      karyawan["role_id"] = row["role_id"];
      karyawan["is_active"] = row["is_active"];
    }

    var response = jsonEncode(_responseSuccessMsg(karyawan));
    return Response.ok(response.toString());
  }

  Future<Response> getUserDataFilter(Request request) async {
    String body = await request.readAsString();
    var obj = json.decode(body);
    var name = "%" + obj['nama_karyawan'] + "%";

    var conn = await connectSql();
    var sql = "SELECT * FROM KARYAWAN WHERE nama_karyawan like ?";
    var user = await conn.query(sql, [name]);
    var response = _responseSuccessMsg(user.toString());
    return Response.ok(response.toString());
  }

  Future<Response> postUserData(Request request) async {
    String body = await request.readAsString();
    karyawan user = userFromJson(body);

    if (!_isValid(user)) {
      return Response.badRequest(
          body: _responseErrorMsg('Error when validate input data'));
    }

    user.tanggal_input = getDateNow();
    user.modified = getDateNow();

    var conn = await connectSql();
    var sqlExecute = """
    INSERT INTO karyawan (id_karyawan, nama_karyawan, jabatan, gaji, role_id,
    is_active, tanggal_input, modified)
    VALUES
    (
    '${user.id_karyawan}',
    '${user.nama_karyawan}','${user.jabatan}','${user.gaji}','${user.role_id}',
    '${user.is_active}','${user.tanggal_input}','${user.modified}'
    )
    """;

    // ignore: unused_local_variable
    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM USER WHERE nama karyawan = ?";
    var userResponse = await conn.query(sql, [user.nama_karyawan]);

    var response = _responseSuccessMsg(userResponse.toString());
    return Response.ok(response.toString());
  }

  Future<Response> putUserData(Request request) async {
    String body = await request.readAsString();
    karyawan user = userFromJson(body);

    if (!_isValid(user)) {
      return Response.badRequest(
          body: _responseErrorMsg('Error when validate input data'));
    }

    user.modified = getDateNow();

    var conn = await connectSql();
    var sqlExecute = """
      UPDATE user SET
      nama_karyawan ='${user.nama_karyawan}', jabatan = '${user.jabatan}',
      gaji = '${user.gaji}', role_id = '${user.role_id}',
      modified='${user.modified}'
      WHERE iduser ='${user.id_karyawan}'
      """;

    // ignore: unused_local_variable
    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM USER WHERE id_karyawan = ?";
    var userResponse = await conn.query(sql, [user.id_karyawan]);

    var response = _responseSuccessMsg(userResponse.toString());
    return Response.ok(response.toString());
  }

  Future<Response> deleteUser(Request request) async {
    String body = await request.readAsString();
    karyawan user = userFromJson(body);

    var conn = await connectSql();
    var sqlExecute = """
    DELETE FROM USER WHERE iduser ='${user.id_karyawan}'""";

    // ignore: unused_local_variable
    var execute = await conn.query(sqlExecute, []);

    var sql = "SELECT * FROM USER WHERE iduser = ?";
    var userResponse = await conn.query(sql, [user.id_karyawan]);

    var response = _responseSuccessMsg(userResponse.toString());
    return Response.ok(response.toString());
  }

  Future<Response> signUp(Request request) async {
    String body = await request.readAsString();
    var obj = json.decode(body);
    var email = "%${obj['email']}%";

    var conn = await connectSql();
    var sql = "SELECT * FROM USER WHERE email like ?";
    var user = await conn.query(sql, [email]);
    if (user.isNotEmpty) {
      var strBase = "";

      for (var row in user) {
        strBase =
            '{"iduser": ${row["iduser"]},"email": "${row["email"]}", "password": "${row["password"]}" }';
      }

      final bytes = utf8.encode(strBase.toString());
      final base64Str = base64.encode(bytes);
      final token = "Bearer-$base64Str";
      var response = _responseSuccessMsg(token);
      return Response.ok(jsonEncode(response));
    } else {
      var response = _responseErrorMsg('User Not Found');
      return Response.forbidden(jsonEncode(response));
    }
  }

  /* Date Time */
  String getDateNow() {
    final DateTime now = DateTime.now();
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String dateNow = dateFormat.format(now);
    return dateNow;
  }

  /*
    FUNCTION FOR AUTHORIZATION
  */

  bool _isValid(karyawan user) {
    if (user.nama_karyawan == null ||
        user.jabatan == null ||
        user.gaji == null ||
        user.role_id == 0) {
      return false;
    }

    return true;
  }

  Future<bool> _isValidRequestHeader(Request request) async {
    //final authorizationHeader = request.headers['Authorization'] ?? request.headers['authorization'];
    //return Response.ok(authorizationHeader);

    // final token = request.headers['token'] ?? request.headers['token'];
    // return Response.ok(token);

    final authHeader =
        request.headers['Authorization'] ?? request.headers['authorization'];
    final parts = authHeader?.split('-');

    if (parts == null || parts.length != 2 || !parts[0].contains('Bearer')) {
      return false;
    }

    final token = parts[1];
    var validUser = await _isValidToken(token);
    if (validUser) {
      return true;
    } else {
      return false;
    }
  }

  Future<Response> getCheckAuth(Request request) async {
    String result = "";
    final isValidRequest = await _isValidRequestHeader(request);
    if (isValidRequest) {
      result = '{"isValid": true}';
      return Response.ok(result.toString());
    } else {
      result = '{"isValid": false}';
      return Response.forbidden(result.toString());
    }
  }

  // verify the token
  Future<bool> _isValidToken(String token) async {
    final str = utf8.decode(base64.decode(token));
    var obj = json.decode(str);
    var iduser = obj['iduser'];

    var conn = await connectSql();
    var sql = "SELECT * FROM USER WHERE iduser = ?";
    var user = await conn.query(sql, [iduser]);

    if (user.isEmpty) {
      return false;
    } else {
      return true;
    }
  }
}

Map<String, dynamic> _responseSuccessMsg(dynamic msg) {
  return {'status': 200, 'Success': true, 'data': msg};
}

Map<String, dynamic> _responseErrorMsg(dynamic msg) {
  return {'status': 400, 'Success': false, 'data': msg};
}
