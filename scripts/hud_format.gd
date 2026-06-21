class_name HudFormat
extends RefCounted
## Presentation-only number formatting for the telemetry HUD. No physics.


static func mass_msun(m: float) -> String:
	if m < 100.0:
		return "%.1f M☉" % m
	if m < 1.0e5:
		return "%.0f M☉" % m
	return "%s M☉" % sci(m, 2)


static func erg_per_s(l: float) -> String:
	return "%s erg/s" % sci(l, 3)


static func grams_per_s(mdot: float) -> String:
	return "%s g/s" % sci(mdot, 3)


static func kelvin(t: float) -> String:
	if t >= 1.0e6:
		return "%.2f MK" % (t / 1.0e6)
	if t >= 1.0e3:
		return "%.1f kK" % (t / 1.0e3)
	return "%.0f K" % t


static func cm(r: float) -> String:
	return "%s cm" % sci(r, 3)


static func lambda_edd(lam: float) -> String:
	if lam >= 100.0:
		return "%.0f× Edd" % lam
	if lam >= 10.0:
		return "%.1f× Edd" % lam
	return "%.3f× Edd" % lam


static func sci(x: float, sig: int) -> String:
	if x == 0.0:
		return "0"
	var exp := int(floor(log(abs(x)) / log(10.0)))
	var mant := x / pow(10.0, exp)
	var fmt := "%." + str(sig - 1) + "f"
	return (fmt % mant) + "×10^" + str(exp)
