enum BookingStatus {
  pending,
  confirmed,
  declined,
  inProgress,
  completed,
  cancelled
}

class Booking {
  final String id;
  final String clientId;
  final String providerId;
  final String serviceType; // 'pet_sitting', 'dog_walking', etc.
  final BookingStatus status;
  final double totalPrice;
  
  // O novo calendário: Lista de datas selecionadas
  final List<DateTime> scheduledDates;
  
  // Fase de Execução
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  
  // Relacionamentos (Carregados via join)
  final List<String> animalIds; // IDs dos animais neste serviço

  Booking({
    required this.id,
    required this.clientId,
    required this.providerId,
    required this.serviceType,
    required this.status,
    required this.totalPrice,
    required this.scheduledDates,
    this.checkInTime,
    this.checkOutTime,
    this.animalIds = const [],
  });

  // Helper para saber se é hoje o dia do serviço
  bool get isToday {
    final now = DateTime.now();
    return scheduledDates.any((date) => 
      date.year == now.year && date.month == now.month && date.day == now.day
    );
  }

  // Helper para saber quantas noites/dias são
  int get durationInDays => scheduledDates.length;

  Map<String, dynamic> toMap() {
    return {
      'client_id': clientId,
      'provider_id': providerId,
      'service_type': serviceType,
      'status': status.name, // ou toLowerCase()
      'total_price': totalPrice,
      // Converter List<DateTime> para List<String> formato ISO YYYY-MM-DD para o Postgres DATE[]
      'scheduled_dates': scheduledDates.map((d) => d.toIso8601String().split('T')[0]).toList(),
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    // Helper seguro para converter status string em Enum
    BookingStatus parseStatus(String? status) {
      return BookingStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == (status?.toLowerCase() ?? 'pending'),
        orElse: () => BookingStatus.pending,
      );
    }

    // Converter Postgres Array DATE[] para List<DateTime>
    List<DateTime> parseDates(dynamic dates) {
      if (dates == null) return [];
      if (dates is List) {
        return dates.map((d) => DateTime.parse(d.toString())).toList();
      }
      return [];
    }

    return Booking(
      id: map['id'] ?? '',
      clientId: map['client_id'] ?? '',
      providerId: map['provider_id'] ?? '',
      serviceType: map['service_type'] ?? '',
      status: parseStatus(map['status']),
      totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0.0,
      scheduledDates: parseDates(map['scheduled_dates']),
      checkInTime: map['check_in_time'] != null ? DateTime.parse(map['check_in_time']) : null,
      checkOutTime: map['check_out_time'] != null ? DateTime.parse(map['check_out_time']) : null,
      // Se fizeres o join, os animais virão aqui, senão começa vazio
      animalIds: [], 
    );
  }
}