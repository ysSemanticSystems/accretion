#!/usr/bin/env python3
"""Generate accretion-core golden fixtures from astropy. Oracle for Rust golden tests.

Radii are expressed as multiples of the Schwarzschild radius (legible, documented).
Kerr geometry and blackbody RGB use the same closed forms / integration as Rust.
"""
from __future__ import annotations

import json
import math
from pathlib import Path

import astropy
import astropy.constants as c

G = float(c.G.cgs.value)
C = float(c.c.cgs.value)
M_SUN = float(c.M_sun.cgs.value)
M_P = float(c.m_p.cgs.value)
SIGMA_T = float(c.sigma_T.cgs.value)
SIGMA_SB = float(c.sigma_sb.cgs.value)
H_PLANCK = float(c.h.cgs.value)
K_BOLTZMANN = float(c.k_B.cgs.value)
NM_TO_CM = 1.0e-7


def l_edd(m: float) -> float:
    return 4 * math.pi * G * (m * M_SUN) * M_P * C / SIGMA_T


def r_s(m: float) -> float:
    return 2 * G * (m * M_SUN) / C**2


def disk_t(r: float, m: float, md: float) -> float:
    return (3 * G * (m * M_SUN) * md / (8 * math.pi * SIGMA_SB * r**3)) ** 0.25


def isco_radius(spin: float) -> float:
    a = spin
    z1 = 1.0 + (1.0 - a * a) ** (1.0 / 3.0) * (
        (1.0 + a) ** (1.0 / 3.0) + (1.0 - a) ** (1.0 / 3.0)
    )
    z2 = math.sqrt(3.0 * a * a + z1 * z1)
    return 3.0 + z2 - math.sqrt((3.0 - z1) * (3.0 + z1 + 2.0 * z2))


def outer_horizon_radius_rg(spin: float) -> float:
    a = spin
    return 1.0 + math.sqrt(max(1.0 - a * a, 0.0))


def isco_specific_energy(spin: float) -> float:
    a = spin
    r = isco_radius(spin)
    sqrt_r = math.sqrt(r)
    r32 = r * sqrt_r
    r34 = math.sqrt(r32)
    numerator = r32 - 2.0 * sqrt_r + a
    denominator = r34 * math.sqrt(r32 - 3.0 * sqrt_r + 2.0 * a)
    return numerator / denominator


def efficiency_from_spin(spin: float) -> float:
    return 1.0 - isco_specific_energy(spin)


def _cie_xyz_cmf(lambda_nm: float) -> tuple[float, float, float]:
    def gauss(lam: float, mean: float, sigma_lo: float, sigma_hi: float) -> float:
        sigma = sigma_lo if lam < mean else sigma_hi
        t = (lam - mean) / sigma
        return math.exp(-0.5 * t * t)

    x = (
        1.056 * gauss(lambda_nm, 599.8, 37.9, 31.0)
        + 0.362 * gauss(lambda_nm, 442.0, 16.0, 26.7)
        - 0.065 * gauss(lambda_nm, 501.1, 20.4, 26.2)
    )
    y = 0.821 * gauss(lambda_nm, 568.8, 46.9, 40.5) + 0.286 * gauss(
        lambda_nm, 530.9, 16.3, 31.1
    )
    z = 1.217 * gauss(lambda_nm, 437.0, 11.8, 36.0) + 0.681 * gauss(
        lambda_nm, 459.0, 26.0, 13.8
    )
    return x, y, z


def blackbody_rgb(temp_k: float) -> tuple[float, float, float]:
    if temp_k <= 0.0 or not math.isfinite(temp_k):
        return 0.0, 0.0, 0.0
    x_sum = y_sum = z_sum = 0.0
    lambda_nm = 380.0
    while lambda_nm <= 780.0:
        lambda_cm = lambda_nm * NM_TO_CM
        exponent = H_PLANCK * C / (lambda_cm * K_BOLTZMANN * temp_k)
        b = (2.0 * H_PLANCK * C * C / lambda_cm**5) / (math.exp(exponent) - 1.0)
        xb, yb, zb = _cie_xyz_cmf(lambda_nm)
        x_sum += b * xb
        y_sum += b * yb
        z_sum += b * zb
        lambda_nm += 5.0
    total = x_sum + y_sum + z_sum
    if total <= 0.0:
        return 0.0, 0.0, 0.0
    x = x_sum / total
    y = y_sum / total
    z = z_sum / total
    r = max(0.0, 3.240625 * x - 1.537208 * y - 0.498629 * z)
    g = max(0.0, -0.968931 * x + 1.875756 * y + 0.041518 * z)
    b = max(0.0, 0.055710 * x - 0.204021 * y + 1.056996 * z)
    peak = max(r, g, b)
    if peak <= 0.0:
        return 0.0, 0.0, 0.0
    return r / peak, g / peak, b / peak


cases: list[dict] = []

cases.append(
    {"fn": "sigma_sb", "args": {}, "expected": float(c.sigma_sb.cgs.value)}
)
cases.append({"fn": "sigma_t", "args": {}, "expected": float(c.sigma_T.cgs.value)})

for m in (10.0, 1.0e6, 6.5e9):
    cases.append({"fn": "l_eddington", "args": {"m_bh_msun": m}, "expected": l_edd(m)})

M, MD = 10.0, 1.0e18
for k in (10.0, 20.0):
    r = k * r_s(M)
    cases.append(
        {
            "fn": "disk_temperature",
            "args": {"m_bh_msun": M, "mdot_gs": MD, "r_cm": r},
            "radius": f"{k}*R_S",
            "expected": disk_t(r, M, MD),
        }
    )

for spin in (0.0, 0.5, 0.998):
    cases.append(
        {
            "fn": "outer_horizon_radius_rg",
            "args": {"spin": spin},
            "expected": outer_horizon_radius_rg(spin),
        }
    )

for spin in (0.0, 0.9):
    cases.append(
        {"fn": "isco_radius", "args": {"spin": spin}, "expected": isco_radius(spin)}
    )
    cases.append(
        {
            "fn": "efficiency_from_spin",
            "args": {"spin": spin},
            "expected": efficiency_from_spin(spin),
        }
    )

for temp_k in (1.0e4, 1.0e6, 1.0e7):
    r, g, b = blackbody_rgb(temp_k)
    cases.append(
        {
            "fn": "blackbody_rgb",
            "args": {"temp_k": temp_k},
            "expected": {"r": r, "g": g, "b": b},
        }
    )

out_path = Path("crates/accretion-core/tests/fixtures/golden.json")
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(
    json.dumps({"source": f"astropy {astropy.__version__}", "cases": cases}, indent=2)
    + "\n"
)
print("wrote golden.json")
