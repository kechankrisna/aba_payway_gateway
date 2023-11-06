import 'dart:convert';

import 'package:dart_payway_partner/dart_payway_partner.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class PaywayPartnerService {
  late PaywayPartner partner;

  PaywayPartnerService({required this.partner});

  PaywayPartnerClientService? get helper => PaywayPartnerClientService(partner);
}
