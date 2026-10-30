"""
convert_manastiri.py
Script de unica folosinta: converteste manastiri_de_vizitat.xlsx -> manastiri.json

Utilizare:
    pip install pandas openpyxl
    python convert_manastiri.py

Output: manastiri.json (pune-l in assets/ din proiectul Flutter)
"""

import json
import re
import pandas as pd

INPUT_FILE = "manastiri_de_vizitat.xlsx"
OUTPUT_FILE = "manastiri.json"

# Normalizare judete (corecteaza diacritice lipsa si duplicate)
JUDET_MAP = {
    "Bucuresti": "București",
    "Buzau": "Buzău",
    "Constanta": "Constanța",
    "Dambovita": "Dâmbovița",
    "Galati": "Galați",
    "Mehedinti": "Mehedinți",
    "Salaj": "Sălaj",
    "Timis": "Timiș",
    "Valcea": "Vâlcea",
}

def normalizeaza_judet(judet):
    if not isinstance(judet, str):
        return ""
    judet = judet.strip()
    return JUDET_MAP.get(judet, judet)

def parse_gps(gps_str):
    """'45.123, 23.456' -> (45.123, 23.456) sau None daca lipseste"""
    if not isinstance(gps_str, str):
        return None, None
    parts = gps_str.strip().split(",")
    if len(parts) != 2:
        return None, None
    try:
        lat = float(parts[0].strip())
        lon = float(parts[1].strip())
        return round(lat, 8), round(lon, 8)
    except ValueError:
        return None, None

def curata_text(val):
    if not isinstance(val, str):
        return ""
    return val.strip()

def curata_int(val):
    try:
        return int(val)
    except (TypeError, ValueError):
        return None

def main():
    df = pd.read_excel(INPUT_FILE)

    # Redenumim coloanele la nume clare
    df = df.rename(columns={
        "Unnamed: 2": "nume",
        "hram ":      "hram",
        "tip ":       "tip",
    })

    # Sarim primul rand (era header duplicat in xlsx)
    df = df[df["nume"].notna() & (df["nume"] != "NaN")].copy()

    manastiri = []
    sarite = []

    for _, row in df.iterrows():
        nume = curata_text(row.get("nume"))
        if not nume:
            continue

        lat, lon = parse_gps(row.get("coordonate gps"))

        # Manastirile fara GPS sunt incluse dar marcate explicit
        # (nu le putem sorta dupa distanta, dar le afisam cu avertisment)
        are_gps = lat is not None and lon is not None

        if not are_gps:
            sarite.append(nume)

        entry = {
            "id":             len(manastiri) + 1,
            "nume":           nume,
            "judet":          normalizeaza_judet(row.get("județ")),
            "tip":            curata_text(row.get("tip")),       # "calugari" | "maici" | ""
            "hram":           curata_text(row.get("hram")),
            "an":             curata_int(row.get("an")),
            "regiune":        curata_text(row.get("regiune")),
            "arhiepiscopie":  curata_text(row.get("arhiepiscopie")),
            "mitropolie":     curata_text(row.get("mitropolie")),
            "vietuitori":     curata_int(row.get("vietuitori")),
            "lat":            lat,
            "lon":            lon,
        }
        manastiri.append(entry)

    # Sortam alfabetic dupa judet + nume (ordinea din JSON nu conteaza in Flutter,
    # dar ajuta daca vrei sa inspectezi fisierul manual)
    manastiri.sort(key=lambda m: (m["judet"], m["nume"]))

    # Reindexam ID-urile dupa sortare
    for i, m in enumerate(manastiri):
        m["id"] = i + 1

    output = {
        "versiune": 1,
        "total": len(manastiri),
        "fara_gps": len(sarite),
        "manastiri": manastiri,
    }

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"✓ Exportat {len(manastiri)} manastiri in {OUTPUT_FILE}")
    print(f"  Dintre care {len(sarite)} fara coordonate GPS:")
    for s in sarite:
        print(f"    - {s}")
    print(f"\nPune fisierul '{OUTPUT_FILE}' in 'assets/' din proiectul Flutter")
    print("si adauga in pubspec.yaml:")
    print("  flutter:")
    print("    assets:")
    print("      - assets/manastiri.json")

if __name__ == "__main__":
    main()
