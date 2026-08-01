import 'chart.dart';
import 'dasha.dart';
import 'divisional.dart';
import 'panchang.dart';

/// Public entry point of the engine.
///
/// ## Licensing
///
/// Implementations of this interface link against Swiss Ephemeris under AGPL-3.0.
/// They must only be executed in client-side contexts — a mobile application on the
/// user's device, or WebAssembly in the user's browser.
///
/// Invoking this from a server process places the entire surrounding service under
/// AGPL-3.0 and obliges you to publish its source. See `docs/AGPL-BOUNDARY.md`.
abstract interface class JyotishEngine {
  /// Computes the rasi (D1) chart.
  Chart computeChart(BirthData birthData);

  /// Derives a divisional chart from an already computed rasi chart.
  Chart computeDivisional(Chart rasi, Varga varga);

  /// Computes the Vimshottari dasha tree to the requested depth.
  ///
  /// [depth] 1 returns mahadashas only, 2 adds antardashas, 3 adds pratyantardashas.
  List<DashaPeriod> computeDashas(Chart chart, {int depth = 3});

  /// Computes panchang for a date and location.
  Panchang computePanchang(DateTime utcDate, double latitude, double longitude);

  /// Computes current positions for comparison against a natal chart.
  Chart computeTransits(DateTime utcDateTime, Chart natal);

  /// Releases native resources. Must be called when the engine is no longer needed.
  void dispose();
}
