#!/usr/bin/env python3
"""Generate accretion-core golden fixtures from astropy. Oracle for Rust golden tests.

Radii are expressed as multiples of the Schwarzschild radius (legible, documented).
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


def l_edd(m: float) -> float:
    return 4 * math.pi * G * (m * M_SUN) * M_P * C / SIGMA_T


def r_s(m: float) -> float:
    return 2 * G * (m * M_SUN) / C**2


def disk_t(r: float, m: float, md: float) -> float:
    return (3 * G * (m * M_SUN) * md / (8 * math.pi * SIGMA_SB * r**3)) ** 0.25


cases: list[dict] = []

# Derived constants: pin the Rust derivation against astropy's tabulated value.
# sigma_sb is exact (2019 SI); sigma_T is consistent to CODATA's internal
# precision (the Rust value uses alpha; astropy uses e/eps0/m_e).
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

out_path = Path("crates/accretion-core/tests/fixtures/golden.json")
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(
    json.dumps({"source": f"astropy {astropy.__version__}", "cases": cases}, indent=2)
    + "\n"
)
print("wrote golden.json")
