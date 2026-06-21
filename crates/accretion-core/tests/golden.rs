//! Oracle-driven golden tests: expected values from `scripts/gen_golden.py` (astropy).

use std::path::PathBuf;

use accretion_core as phys;

/// Relative tolerance for oracle comparison (one part per billion).
const ORACLE_TOL: f64 = 0.000000001;

#[test]
fn golden_matches_astropy_oracle() {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures/golden.json");
    let f = std::fs::read_to_string(path).expect("golden.json missing; run scripts/gen_golden.py");
    let doc: serde_json::Value = serde_json::from_str(&f).expect("invalid golden.json");

    for case in doc["cases"].as_array().expect("cases array") {
        let exp = case["expected"].as_f64().expect("expected f64");
        let got = match case["fn"].as_str().expect("fn name") {
            "sigma_sb" => phys::derived::SIGMA_SB,
            "sigma_t" => phys::derived::SIGMA_T,
            "l_eddington" => phys::l_eddington(case["args"]["m_bh_msun"].as_f64().unwrap()),
            "disk_temperature" => phys::disk_temperature(
                case["args"]["r_cm"].as_f64().unwrap(),
                case["args"]["m_bh_msun"].as_f64().unwrap(),
                case["args"]["mdot_gs"].as_f64().unwrap(),
            ),
            other => panic!("unknown fn {other}"),
        };
        assert!(
            (got - exp).abs() <= ORACLE_TOL * exp.abs(),
            "fn={} got={got} exp={exp}",
            case["fn"]
        );
    }
}
