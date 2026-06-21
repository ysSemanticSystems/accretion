//! Oracle-driven golden tests: expected values from `scripts/gen_golden.py` (astropy).

mod common;

use std::path::PathBuf;

use accretion_core as phys;

use common::{ORACLE_RTOL, assert_relative_eq};

#[test]
fn golden_matches_astropy_oracle() {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures/golden.json");
    let f = std::fs::read_to_string(path).expect("golden.json missing; run scripts/gen_golden.py");
    let doc: serde_json::Value = serde_json::from_str(&f).expect("invalid golden.json");

    for case in doc["cases"].as_array().expect("cases array") {
        let fn_name = case["fn"].as_str().expect("fn name");
        match fn_name {
            "sigma_sb" => {
                let exp = case["expected"].as_f64().expect("expected f64");
                assert_relative_eq(phys::SIGMA_SB, exp, ORACLE_RTOL);
            }
            "sigma_t" => {
                let exp = case["expected"].as_f64().expect("expected f64");
                assert_relative_eq(phys::SIGMA_T, exp, ORACLE_RTOL);
            }
            "l_eddington" => {
                let exp = case["expected"].as_f64().expect("expected f64");
                let got = phys::l_eddington(case["args"]["m_bh_msun"].as_f64().unwrap());
                assert_relative_eq(got, exp, ORACLE_RTOL);
            }
            "disk_temperature" => {
                let exp = case["expected"].as_f64().expect("expected f64");
                let got = phys::disk_temperature(
                    case["args"]["r_cm"].as_f64().unwrap(),
                    case["args"]["m_bh_msun"].as_f64().unwrap(),
                    case["args"]["mdot_gs"].as_f64().unwrap(),
                );
                assert_relative_eq(got, exp, ORACLE_RTOL);
            }
            "outer_horizon_radius_rg" => {
                let exp = case["expected"].as_f64().expect("expected f64");
                let got = phys::outer_horizon_radius_rg(case["args"]["spin"].as_f64().unwrap());
                assert_relative_eq(got, exp, ORACLE_RTOL);
            }
            "isco_radius" => {
                let exp = case["expected"].as_f64().expect("expected f64");
                let got = phys::isco_radius(case["args"]["spin"].as_f64().unwrap());
                assert_relative_eq(got, exp, ORACLE_RTOL);
            }
            "efficiency_from_spin" => {
                let exp = case["expected"].as_f64().expect("expected f64");
                let got = phys::efficiency_from_spin(case["args"]["spin"].as_f64().unwrap());
                assert_relative_eq(got, exp, ORACLE_RTOL);
            }
            "blackbody_rgb" => {
                let exp = &case["expected"];
                let got = phys::blackbody_rgb(case["args"]["temp_k"].as_f64().unwrap());
                assert_relative_eq(got.0, exp["r"].as_f64().unwrap(), ORACLE_RTOL);
                assert_relative_eq(got.1, exp["g"].as_f64().unwrap(), ORACLE_RTOL);
                assert_relative_eq(got.2, exp["b"].as_f64().unwrap(), ORACLE_RTOL);
            }
            other => panic!("unknown fn {other}"),
        }
    }
}
