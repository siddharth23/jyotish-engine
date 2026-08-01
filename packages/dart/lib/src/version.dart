/// Engine version, embedded in every computed result.
///
/// Any change that can alter numerical output MUST increment this. Results are
/// cached and stored by consuming applications keyed on this value; a silent
/// change would make historical charts irreproducible.
const String engineVersion = '0.1.0';
