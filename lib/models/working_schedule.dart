class DaySchedule {
  final bool isOpen;
  final String start;
  final String end;

  DaySchedule({this.isOpen = false, this.start = "09:00", this.end = "18:00"});

  Map<String, dynamic> toMap() => {'isOpen': isOpen, 'start': start, 'end': end};

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    return DaySchedule(
      isOpen: map['isOpen'] ?? false,
      start: map['start'] ?? "09:00",
      end: map['end'] ?? "18:00",
    );
  }
  
  DaySchedule copyWith({bool? isOpen, String? start, String? end}) {
    return DaySchedule(
      isOpen: isOpen ?? this.isOpen,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}

class WorkingSchedule {
  final Map<int, DaySchedule> days; // Regra Base (1=Segunda, 7=Domingo)
  final List<DateTime> blockedDates; // Exceções (Dias específicos bloqueados)

  WorkingSchedule({
    required this.days,
    this.blockedDates = const [],
  });

  // Lógica Central: O dia está disponível?
  bool isDayAvailable(DateTime date) {
    // 1. Verificar Exceções (Ignora a hora, compara apenas Ano/Mês/Dia)
    final isBlocked = blockedDates.any((d) => 
      d.year == date.year && d.month == date.month && d.day == date.day
    );
    if (isBlocked) return false;

    // 2. Verificar Regra Base
    final weekDay = days[date.weekday];
    return weekDay?.isOpen ?? false;
  }

  Map<String, dynamic> toMap() {
    return {
      'days': days.map((key, value) => MapEntry(key.toString(), value.toMap())),
      // Guardamos as datas bloqueadas como lista de Strings ISO
      'blocked_dates': blockedDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  factory WorkingSchedule.fromMap(Map<String, dynamic> map) {
    // Parser dos Dias
    final Map<int, DaySchedule> parsedDays = {};
    if (map['days'] != null) {
      (map['days'] as Map).forEach((key, value) {
        parsedDays[int.parse(key.toString())] = DaySchedule.fromMap(value);
      });
    }
    // Preencher dias em falta
    for (int i = 1; i <= 7; i++) {
      parsedDays.putIfAbsent(i, () => DaySchedule(isOpen: false));
    }

    // Parser das Exceções
    List<DateTime> parsedBlocked = [];
    if (map['blocked_dates'] != null) {
      parsedBlocked = (map['blocked_dates'] as List)
          .map((e) => DateTime.parse(e.toString()))
          .toList();
    }

    return WorkingSchedule(
      days: parsedDays,
      blockedDates: parsedBlocked,
    );
  }
  
  factory WorkingSchedule.empty() {
    return WorkingSchedule(
      days: {
        1: DaySchedule(isOpen: true),
        2: DaySchedule(isOpen: true),
        3: DaySchedule(isOpen: true),
        4: DaySchedule(isOpen: true),
        5: DaySchedule(isOpen: true),
        6: DaySchedule(isOpen: false),
        7: DaySchedule(isOpen: false),
      },
      blockedDates: [],
    );
  }
}