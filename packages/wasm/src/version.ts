/**
 * The engine contract this build implements.
 *
 * **Must equal `engineVersion` in packages/dart.** Consuming applications cache and
 * store results keyed on this value, so any change that can alter numerical output
 * must increment it. CI fails when the two declarations diverge.
 */
export const ENGINE_VERSION = '0.3.0';
