import 'dart:convert';
import 'controller.dart';

class karyawan {
  final int id_karyawan;
  final String? nama_karyawan;
  final String? jabatan;
  final int? gaji;
  final int role_id;
  final int is_active;
  String? tanggal_input;
  String? modified;

  karyawan({
    required this.id_karyawan,
    required this.nama_karyawan,
    required this.jabatan,
    required this.gaji,
    required this.role_id,
    required this.is_active,
    required this.tanggal_input,
    required this.modified,
  });

  Map<String, dynamic> toMap() => {
        'id_karyawan': id_karyawan,
        'nama_karyawan': nama_karyawan,
        'jabatan': jabatan,
        'gaji': gaji,
        'role_id': role_id,
        'is_active': is_active,
        'tanggal_input': tanggal_input,
        'modified': modified
      };

  final Controller ctrl = Controller();

  factory karyawan.fromJson(Map<String, dynamic> json) => karyawan(
        id_karyawan: json['id_karyawan'],
        nama_karyawan: json['nama_karyawan'],
        jabatan: json['jabatan'],
        gaji: json['gaji'],
        role_id: json['role_id'],
        is_active: 1,
        tanggal_input: json['tanggal_input'],
        modified: json['modified'],
      );
}

karyawan userFromJson(String str) => karyawan.fromJson(json.decode(str));
