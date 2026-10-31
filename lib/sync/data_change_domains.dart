import 'package:flutter/foundation.dart';

/// Domains representing logical UI / data boundaries that can be refreshed.
enum DataDomain {
  people,
  attendance,
  behavior,
  visitation,
  buses,
  areas,
  stages,
  khoros,
  fathers,
  services,
  fields,
  family,
  documents,
  tayo,
  settings,
  analytics,
  reports,
  access,
}

/// Normalizes raw table names from various sources (PostgreSQL, SQLite, SignalR JSON, casing, schemas).
String normalizeTableName(String rawName) {
  var name = rawName.trim();
  // Strip surrounding quotes
  if ((name.startsWith('"') && name.endsWith('"')) ||
      (name.startsWith("'") && name.endsWith("'"))) {
    name = name.substring(1, name.length - 1).trim();
  }
  // Strip schema prefix if present (e.g. public.persons -> persons)
  if (name.contains('.')) {
    name = name.split('.').last.trim();
  }
  return name.toLowerCase();
}

/// Table dependency mappings to data domains.
final Map<String, Set<DataDomain>> _tableToDomainsMap = {
  'persons': {
    DataDomain.people,
    DataDomain.attendance,
    DataDomain.behavior,
    DataDomain.visitation,
    DataDomain.buses,
    DataDomain.family,
    DataDomain.documents,
    DataDomain.tayo,
    DataDomain.analytics,
    DataDomain.reports,
  },
  'person_services': {
    DataDomain.people,
    DataDomain.services,
    DataDomain.reports,
  },
  'stages': {
    DataDomain.stages,
    DataDomain.people,
    DataDomain.attendance,
    DataDomain.visitation,
    DataDomain.buses,
    DataDomain.family,
    DataDomain.analytics,
    DataDomain.reports,
  },
  'stage_services': {
    DataDomain.stages,
    DataDomain.services,
    DataDomain.people,
    DataDomain.analytics,
    DataDomain.reports,
  },
  'khoroses': {
    DataDomain.khoros,
    DataDomain.people,
    DataDomain.attendance,
    DataDomain.visitation,
    DataDomain.buses,
    DataDomain.analytics,
    DataDomain.reports,
  },
  'khoros_services': {
    DataDomain.khoros,
    DataDomain.services,
    DataDomain.people,
    DataDomain.analytics,
    DataDomain.reports,
  },
  'areas': {
    DataDomain.areas,
    DataDomain.people,
    DataDomain.attendance,
    DataDomain.visitation,
    DataDomain.buses,
    DataDomain.family,
    DataDomain.analytics,
    DataDomain.reports,
  },
  'fathers': {
    DataDomain.fathers,
    DataDomain.people,
    DataDomain.attendance,
    DataDomain.visitation,
    DataDomain.family,
    DataDomain.analytics,
    DataDomain.reports,
  },
  'services': {
    DataDomain.services,
    DataDomain.stages,
    DataDomain.khoros,
    DataDomain.people,
    DataDomain.attendance,
    DataDomain.behavior,
    DataDomain.visitation,
    DataDomain.tayo,
    DataDomain.analytics,
    DataDomain.reports,
  },
  'coming': {
    DataDomain.attendance,
    DataDomain.behavior,
    DataDomain.visitation,
    DataDomain.buses,
    DataDomain.analytics,
    DataDomain.reports,
  },
  'absent_persons': {
    DataDomain.attendance,
    DataDomain.analytics,
    DataDomain.reports,
  },
  'absent_print': {
    DataDomain.attendance,
  },
  'adding': {
    DataDomain.attendance,
  },
  'credit': {
    DataDomain.attendance,
  },
  'visitations': {
    DataDomain.visitation,
    DataDomain.attendance,
    DataDomain.reports,
  },
  'bus_drivers': {
    DataDomain.buses,
  },
  'bus_assignments': {
    DataDomain.buses,
  },
  'jender': {
    DataDomain.people,
    DataDomain.analytics,
    DataDomain.reports,
  },
  'custom_field_definitions': {
    DataDomain.fields,
    DataDomain.people,
    DataDomain.visitation,
    DataDomain.reports,
  },
  'person_custom_field_values': {
    DataDomain.fields,
    DataDomain.people,
    DataDomain.visitation,
    DataDomain.reports,
  },
  'person_documents': {
    DataDomain.documents,
  },
  'family_relationships': {
    DataDomain.family,
  },
  'tayo_cards': {
    DataDomain.tayo,
  },
  'person_tayo_points': {
    DataDomain.tayo,
  },
  'settings': {
    DataDomain.settings,
    DataDomain.people,
    DataDomain.attendance,
    DataDomain.visitation,
    DataDomain.reports,
    DataDomain.services,
  },
  'pass': {
    DataDomain.access,
  },
  'user_permissions_ext': {
    DataDomain.access,
  },
  'user_visibility_filters': {
    DataDomain.access,
    DataDomain.people,
    DataDomain.attendance,
    DataDomain.analytics,
    DataDomain.reports,
  },
};

/// Resolves which DataDomains are affected by a given collection of table names.
/// If '*' or empty is supplied, or if an unknown table is encountered,
/// conservative fallback is used to ensure no UI gets stuck.
Set<DataDomain> resolveDomainsForTables(Iterable<String> rawTableNames) {
  if (rawTableNames.isEmpty) {
    return DataDomain.values.toSet();
  }

  final result = <DataDomain>{};
  bool allStale = false;

  for (final raw in rawTableNames) {
    final normalized = normalizeTableName(raw);
    if (normalized == '*' || normalized.isEmpty) {
      allStale = true;
      break;
    }

    final domains = _tableToDomainsMap[normalized];
    if (domains != null) {
      result.addAll(domains);
    } else {
      // Diagnostic log without leaking personal data
      debugPrint('[DataChangeDomains] Encountered unknown table: "$raw" (normalized: "$normalized"). Marking all domains stale.');
      allStale = true;
      break;
    }
  }

  if (allStale) {
    return DataDomain.values.toSet();
  }

  return result;
}
