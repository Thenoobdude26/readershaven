import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─────────────────────────────────────────────────────────────
  // Genre Filter Tests
  // ─────────────────────────────────────────────────────────────

  group('Genre Filter', () {
    final stories = [
      {'title': 'Wings of a Hunter', 'genre': 'Fantasy'},
      {'title': 'Love in Kuala Lumpur', 'genre': 'Romance'},
      {'title': 'Dark Spells', 'genre': 'Fantasy'},
      {'title': 'The Last Signal', 'genre': 'Sci-Fi'},
    ];

    test('returns only stories matching selected genre', () {
      final filtered = stories
          .where((s) => s['genre'] == 'Fantasy')
          .toList();

      expect(filtered.length, 2);
      expect(filtered.every((s) => s['genre'] == 'Fantasy'), true);
    });

    test('returns all stories when genre is All', () {
      const selectedGenre = 'All';
      final filtered = selectedGenre == 'All'
          ? stories
          : stories.where((s) => s['genre'] == selectedGenre).toList();

      expect(filtered.length, 4);
    });

    test('returns empty list when no stories match genre', () {
      final filtered = stories
          .where((s) => s['genre'] == 'Horror')
          .toList();

      expect(filtered.isEmpty, true);
    });

    test('search filter matches by title', () {
      const query = 'wings';
      final filtered = stories.where((s) {
        return (s['title'] ?? '').toLowerCase().contains(query);
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first['title'], 'Wings of a Hunter');
    });

    test('search filter is case insensitive', () {
      const query = 'LOVE';
      final filtered = stories.where((s) {
        return (s['title'] ?? '').toLowerCase().contains(query.toLowerCase());
      }).toList();

      expect(filtered.length, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Reading Progress Tests
  // ─────────────────────────────────────────────────────────────

  group('Reading Progress', () {
    double calculateProgress(double offset, double maxScroll) {
      if (maxScroll == 0) return 0.0;
      return (offset / maxScroll).clamp(0.0, 1.0);
    }

    test('progress is 0.0 at start', () {
      expect(calculateProgress(0, 1000), 0.0);
    });

    test('progress is 1.0 at end', () {
      expect(calculateProgress(1000, 1000), 1.0);
    });

    test('progress is 0.5 at halfway', () {
      expect(calculateProgress(500, 1000), 0.5);
    });

    test('progress is clamped to 1.0 if over max', () {
      expect(calculateProgress(1200, 1000), 1.0);
    });

    test('progress is clamped to 0.0 if negative', () {
      expect(calculateProgress(-50, 1000), 0.0);
    });

    test('progress returns 0.0 when maxScroll is 0', () {
      expect(calculateProgress(0, 0), 0.0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Role Application Validation Tests
  // ─────────────────────────────────────────────────────────────

  group('Role Application Validation', () {
    String? getNextRole(String currentRole) {
      if (currentRole == 'reader') return 'writer';
      if (currentRole == 'writer') return 'mentor';
      return null; // mentor cannot apply further
    }

    bool canApply(String currentRole) {
      return currentRole == 'reader' || currentRole == 'writer';
    }

    test('reader can apply to become writer', () {
      expect(getNextRole('reader'), 'writer');
      expect(canApply('reader'), true);
    });

    test('writer can apply to become mentor', () {
      expect(getNextRole('writer'), 'mentor');
      expect(canApply('writer'), true);
    });

    test('mentor cannot apply for any role', () {
      expect(getNextRole('mentor'), null);
      expect(canApply('mentor'), false);
    });

    test('reader cannot skip directly to mentor', () {
      // A reader's next role is writer, never mentor
      expect(getNextRole('reader'), isNot('mentor'));
    });
  });
}