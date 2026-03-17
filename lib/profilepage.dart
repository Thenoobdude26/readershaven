import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart';

final supabase = Supabase.instance.client;

class Profilepage extends StatefulWidget{
  const Profilepage({super.key});
}