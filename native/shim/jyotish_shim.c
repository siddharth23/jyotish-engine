/*
 * Thin C interface over Swiss Ephemeris for the WebAssembly build.
 *
 * Returns raw astronomical values only -- longitudes, speeds, the ascendant, house
 * cusps, the ayanamsa and rise/set times. Every derivation (signs, nakshatras,
 * dignity, vargas, dashas) happens in TypeScript, so this file stays small and the
 * seam between the two halves of the engine stays a single flat array.
 *
 * AGPL-3.0-only. Browser use only; see docs/AGPL-BOUNDARY.md.
 */
#include <string.h>

#include "swephexp.h"

#define BODY_COUNT 8
#define BODY_FIELDS 3
#define RAW_LENGTH (BODY_COUNT * BODY_FIELDS + 2 + 12)

/* Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn, then the node chosen per call. */
static const int BODIES[BODY_COUNT - 1] = {
    SE_SUN, SE_MOON, SE_MARS, SE_MERCURY, SE_JUPITER, SE_VENUS, SE_SATURN,
};

void jy_set_ephe_path(const char *path) { swe_set_ephe_path((char *)path); }

int jy_raw_length(void) { return RAW_LENGTH; }

/*
 * Fills out[RAW_LENGTH]:
 *   [0..23]  longitude, latitude, speed for the eight bodies above, sidereal
 *   [24]     sidereal ascendant
 *   [25]     ayanamsa value
 *   [26..37] twelve sidereal house cusps for hsys
 *
 * Returns 0 on success. Returns -1 and writes serr (AS_MAXCH bytes) if any body could
 * not be computed from the Swiss Ephemeris data files. Silently falling back to the
 * Moshier approximation would change output precision without changing the engine
 * version, so it is treated as an error.
 */
int jy_raw(double jd_ut, double latitude, double longitude, int sid_mode, int hsys,
           int true_node, double *out, char *serr) {
  const int32 flags = SEFLG_SWIEPH | SEFLG_SPEED | SEFLG_SIDEREAL;
  double xx[6];
  double cusps[13];
  double ascmc[10];

  serr[0] = '\0';
  swe_set_sid_mode(sid_mode, 0, 0);

  for (int i = 0; i < BODY_COUNT; i++) {
    const int body = i < BODY_COUNT - 1 ? BODIES[i] : (true_node ? SE_TRUE_NODE : SE_MEAN_NODE);
    const int32 result = swe_calc_ut(jd_ut, body, flags, xx, serr);
    if (result < 0) return -1;
    if (body != SE_MEAN_NODE && body != SE_TRUE_NODE && (result & SEFLG_SWIEPH) == 0) {
      strcpy(serr, "Swiss Ephemeris data file unavailable for this date.");
      return -1;
    }
    out[i * BODY_FIELDS] = xx[0];
    out[i * BODY_FIELDS + 1] = xx[1];
    out[i * BODY_FIELDS + 2] = xx[3];
  }

  if (swe_houses_ex(jd_ut, SEFLG_SIDEREAL, latitude, longitude, hsys, cusps, ascmc) < 0) {
    strcpy(serr, "House calculation failed at this latitude.");
    return -1;
  }
  out[BODY_COUNT * BODY_FIELDS] = ascmc[0];

  double ayanamsa = 0;
  if (swe_get_ayanamsa_ex_ut(jd_ut, SEFLG_SWIEPH, &ayanamsa, serr) < 0) return -1;
  out[BODY_COUNT * BODY_FIELDS + 1] = ayanamsa;

  for (int i = 0; i < 12; i++) out[BODY_COUNT * BODY_FIELDS + 2 + i] = cusps[i + 1];
  return 0;
}

/*
 * Next sunrise (rise = 1) or sunset (rise = 0) of the upper limb, with refraction,
 * after jd_ut_start. Writes the time to *out_jd.
 *
 * Returns 0 on success, -2 if the Sun does not cross the horizon (polar day or
 * night), -1 on error with serr set.
 */
int jy_sun_rise_set(double jd_ut_start, double latitude, double longitude, int rise,
                    double *out_jd, char *serr) {
  double geopos[3] = {longitude, latitude, 0};
  serr[0] = '\0';
  const int32 rsmi = rise ? SE_CALC_RISE : SE_CALC_SET;
  return swe_rise_trans(jd_ut_start, SE_SUN, NULL, SEFLG_SWIEPH, rsmi, geopos, 1013.25, 10,
                        out_jd, serr);
}

void jy_close(void) { swe_close(); }
