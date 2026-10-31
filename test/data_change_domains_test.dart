import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/sync/data_change_domains.dart';

void main() {
  group('data_change_domains tests', () {
    test('normalizes raw table names correctly', () {
      expect(normalizeTableName('Persons'), 'persons');
      expect(normalizeTableName('  "Coming"  '), 'coming');
      expect(normalizeTableName("'public.Areas'"), 'areas');
      expect(normalizeTableName('public.custom_field_definitions'), 'custom_field_definitions');
      expect(normalizeTableName('STAGE_SERVICES'), 'stage_services');
    });

    test('maps persons table to dependent domains', () {
      final domains = resolveDomainsForTables(['persons']);
      expect(domains, contains(DataDomain.people));
      expect(domains, contains(DataDomain.attendance));
      expect(domains, contains(DataDomain.behavior));
      expect(domains, contains(DataDomain.visitation));
      expect(domains, contains(DataDomain.buses));
      expect(domains, contains(DataDomain.family));
      expect(domains, contains(DataDomain.documents));
      expect(domains, contains(DataDomain.tayo));
      expect(domains, contains(DataDomain.analytics));
      expect(domains, contains(DataDomain.reports));
    });

    test('renaming area or stage updates people and attendance domains', () {
      final areaDomains = resolveDomainsForTables(['areas']);
      expect(areaDomains, contains(DataDomain.areas));
      expect(areaDomains, contains(DataDomain.people));
      expect(areaDomains, contains(DataDomain.attendance));

      final stageDomains = resolveDomainsForTables(['stages']);
      expect(stageDomains, contains(DataDomain.stages));
      expect(stageDomains, contains(DataDomain.people));
      expect(stageDomains, contains(DataDomain.attendance));
    });

    test('coming table affects attendance, behavior, buses, analytics, and reports', () {
      final comingDomains = resolveDomainsForTables(['coming']);
      expect(comingDomains, contains(DataDomain.attendance));
      expect(comingDomains, contains(DataDomain.behavior));
      expect(comingDomains, contains(DataDomain.visitation));
      expect(comingDomains, contains(DataDomain.buses));
      expect(comingDomains, contains(DataDomain.analytics));
      expect(comingDomains, contains(DataDomain.reports));
      // Should not affect unrelated domains like fields or fathers
      expect(comingDomains, isNot(contains(DataDomain.fields)));
      expect(comingDomains, isNot(contains(DataDomain.fathers)));
    });

    test('wildcard * marks all domains stale', () {
      final domains = resolveDomainsForTables(['*']);
      expect(domains, equals(DataDomain.values.toSet()));
    });

    test('unknown table triggers conservative all domains fallback', () {
      final domains = resolveDomainsForTables(['some_future_table']);
      expect(domains, equals(DataDomain.values.toSet()));
    });

    test('empty collection triggers all domains', () {
      final domains = resolveDomainsForTables([]);
      expect(domains, equals(DataDomain.values.toSet()));
    });
  });
}
