#!/usr/bin/env python3

import json
import sqlite3
from pathlib import Path


QUIZZES = [
    {
        "id": "geography_seas",
        "title": "Seas",
        "subtitle": "Seas",
        "iconName": "waves",
        "access": "free",
        "order": 1,
        "regionIds": [
            "Q4918",
            "Q1247",
            "Q23406",
            "Q166",
            "Q1693",
            "Q545",
            "Q58705",
            "Q37660",
            "Q27092",
            "Q44725",
            "Q82931",
            "Q33254",
            "Q47545",
            "Q45823",
            "Q132868",
            "Q184189",
            "Q13924",
            "Q34575",
            "Q38882",
            "Q47632",
            "Q45341",
            "Q37960",
            "Q5484",
            "Q41602",
            "Q159183",
            "Q44133",
            "Q35000",
            "Q35367",
            "Q181969",
            "Q42820",
        ],
    },
    {
        "id": "geography_mountain_ranges",
        "title": "Mountain ranges",
        "subtitle": "Mountain ranges",
        "iconName": "terrain",
        "access": "free",
        "order": 2,
        "regionIds": [
            "Q5456",
            "Q5463",
            "Q93332",
            "Q192583",
            "Q130135",
            "Q5451",
            "Q5955",
            "Q5474",
            "Q183295",
            "Q5472",
            "Q1288",
            "Q186547",
            "Q35600",
            "Q5477",
            "Q1286",
            "Q4558",
            "Q4527",
            "Q465055",
            "Q167021",
            "Q1124584",
            "Q144040",
            "Q189915",
            "Q187871",
            "Q12431",
            "Q5469",
            "Q156684",
            "Q166755",
            "Q216593",
            "Q161750",
        ],
    },
    {
        "id": "geography_lakes",
        "title": "Lakes",
        "subtitle": "Lakes",
        "iconName": "water",
        "access": "free",
        "order": 3,
        "regionIds": [
            "Q1066",
            "Q5505",
            "Q1383",
            "Q1169",
            "Q5511",
            "Q5513",
            "Q5525",
            "Q5532",
            "Q5539",
            "Q5492",
            "Q3272",
            "Q1062",
            "Q15288",
            "Q134485",
            "Q166162",
            "Q35342",
            "Q173862",
            "Q173596",
            "Q125888",
            "Q116685",
            "Q181932",
            "Q125309",
            "Q125912",
            "Q202905",
            "Q192770",
            "Q272463",
            "Q192215",
            "Q19253",
            "Q199938",
        ],
    },
    {
        "id": "geography_islands",
        "title": "Islands",
        "subtitle": "Islands",
        "iconName": "landscape",
        "access": "free",
        "order": 4,
        "regionIds": [
            "Q223#island",
            "Q40285",
            "Q36117",
            "Q7463928",
            "Q3492",
            "Q13989",
            "Q23666",
            "Q3812",
            "Q120755",
            "Q3757",
            "Q118863",
            "Q48335",
            "Q586657",
            "Q125384",
            "Q3740828",
            "Q124873",
            "Q22890",
            "Q35581#island",
            "Q4526612",
            "Q22502",
            "Q170479",
            "Q4951156",
            "Q1462",
            "Q25277",
            "Q644636",
            "Q27508031",
            "Q14112",
            "Q34374#island",
            "Q8828",
            "Q3593416",
            "Q81178",
            "Q158129",
            "Q146841",
            "Q7792",
            "Q82601",
            "Q21162",
            "Q13987",
            "Q1081204",
            "Q83067",
            "Q2076337",
            "Q4648",
            "Q40846",
            "Q82859",
            "Q205022",
            "Q514070",
        ],
    },
    {
        "id": "geography_other",
        "title": "Other",
        "subtitle": "Bays, straits, gulfs, deserts, and more",
        "iconName": "explore",
        "access": "free",
        "order": 5,
        "regionIds": [
            "Q38684",
            "Q3040",
            "Q41573",
            "Q216868",
            "Q181857",
            "Q232264",
            "Q223810",
            "Q140290",
            "Q189262",
            "Q48359",
            "Q171846",
            "Q232912",
            "Q127031",
            "Q48365",
            "Q5023",
            "Q35958",
            "Q52052",
            "Q271521",
            "Q12630",
            "Q41430",
            "Q180531",
            "Q34675",
            "Q41837",
            "Q132811",
            "Q131217",
            "Q169523",
            "Q14686",
            "Q192626",
            "Q38272",
            "Q128011",
            "Q21713615",
            "Q5813",
            "Q38095",
            "Q25263#archipelago",
            "Q31945",
            "Q21195",
            "Q23522",
            "Q483134",
            "Q130978",
            "Q178543",
            "Q6583",
            "Q42070",
            "Q47700",
            "Q229269",
            "Q47141",
            "Q131377",
            "Q172691",
            "Q189429",
            "Q179842",
            "Q169966",
            "Q925906",
            "Q118574",
        ],
    },
]

LANGS = ("en", "de", "es", "fr")


def _is_all_upper(value: str) -> bool:
    letters = [char for char in value if char.isalpha()]
    return bool(letters) and all(char.upper() == char for char in letters)


def _titleish(value: str) -> str:
    words = value.strip().split()
    return " ".join(word.capitalize() if _is_all_upper(word) else word for word in words)


def _preferred_english_name(default_name: str, localized: dict[str, str]) -> str:
    english = localized.get("en", "").strip() or default_name.strip()
    und = localized.get("und", "").strip()
    if und:
        if und.startswith("Lake ") or und.endswith(" Lake"):
            return _titleish(und)
        if english.startswith("Mainland "):
            return _titleish(und)
    return english


def _aliases(default_name: str, localized: dict[str, str], english_name: str) -> list[str]:
    aliases: list[str] = []
    for candidate in (
        default_name,
        localized.get("en", ""),
        localized.get("und", ""),
        english_name.removeprefix("Lake "),
        english_name.removesuffix(" Lake"),
    ):
        normalized = candidate.strip()
        if not normalized:
            continue
        if normalized == english_name:
            continue
        if normalized in aliases:
            continue
        aliases.append(_titleish(normalized))
    return aliases


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    db_path = (root / "../flymap-data/outputs/regions_master.db").resolve()
    output_dir = root / "assets/data/geo_quiz/geography"
    output_dir.mkdir(parents=True, exist_ok=True)

    region_ids: list[str] = []
    seen_ids: set[str] = set()
    for quiz in QUIZZES:
        for region_id in quiz["regionIds"]:
            if region_id in seen_ids:
                continue
            seen_ids.add(region_id)
            region_ids.append(region_id)

    placeholders = ",".join("?" for _ in region_ids)
    connection = sqlite3.connect(str(db_path))
    connection.row_factory = sqlite3.Row

    region_rows = connection.execute(
        f"""
        SELECT
          region_id,
          name,
          region_type,
          geom_simplified_json
        FROM regions
        WHERE region_id IN ({placeholders})
        """,
        region_ids,
    ).fetchall()
    region_by_id = {row["region_id"]: row for row in region_rows}

    localization_rows = connection.execute(
        f"""
        SELECT
          region_id,
          lang,
          name,
          description
        FROM regions_localizations
        WHERE region_id IN ({placeholders})
        """,
        region_ids,
    ).fetchall()
    localizations: dict[str, dict[str, sqlite3.Row]] = {}
    for row in localization_rows:
        localizations.setdefault(row["region_id"], {})[row["lang"]] = row

    missing_ids = [region_id for region_id in region_ids if region_id not in region_by_id]
    if missing_ids:
        raise SystemExit(f"Missing regions in DB: {missing_ids}")

    features = []
    names = {"regions": {}}
    descriptions = {lang: {"regions": {}} for lang in LANGS}

    for region_id in region_ids:
        row = region_by_id[region_id]
        geometry = json.loads(row["geom_simplified_json"])
        geometry_type = geometry.get("type")
        if geometry_type not in {"Polygon", "MultiPolygon"}:
            raise SystemExit(f"Unsupported geometry type for {region_id}: {geometry_type}")

        localized = {
            lang: data["name"].strip()
            for lang, data in localizations.get(region_id, {}).items()
            if data["name"] and data["name"].strip()
        }
        default_name = row["name"].strip()
        english_name = _preferred_english_name(default_name, localized)

        region_names = {
            "en": english_name,
            "de": localized.get("de", localized.get("en", default_name)),
            "es": localized.get("es", localized.get("en", default_name)),
            "fr": localized.get("fr", localized.get("en", default_name)),
        }

        names["regions"][region_id] = {
            "names": region_names,
            "aliases": _aliases(default_name, localized, english_name),
            "regionType": row["region_type"],
        }

        for lang in LANGS:
            description_row = localizations.get(region_id, {}).get(lang)
            description = (
                description_row["description"].strip()
                if description_row and description_row["description"]
                else ""
            )
            if description:
                descriptions[lang]["regions"][region_id] = description

        features.append(
            {
                "type": "Feature",
                "id": region_id,
                "properties": {
                    "id": region_id,
                    "regionType": row["region_type"],
                },
                "geometry": geometry,
            }
        )

    quizzes = {
        "quizzes": [
            {
                **{
                    key: value
                    for key, value in quiz.items()
                    if key != "regionIds"
                },
                "totalCount": len(quiz["regionIds"]),
                "isAvailable": True,
                "regionIds": quiz["regionIds"],
            }
            for quiz in QUIZZES
        ]
    }

    (output_dir / "quizzes.json").write_text(
        json.dumps(quizzes, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (output_dir / "geography.geojson").write_text(
        json.dumps(
            {"type": "FeatureCollection", "features": features},
            ensure_ascii=False,
            separators=(",", ":"),
        )
        + "\n",
        encoding="utf-8",
    )
    (output_dir / "geography_names.json").write_text(
        json.dumps(names, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    for lang, payload in descriptions.items():
        (output_dir / f"geography_descriptions_{lang}.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    print(
        f"Wrote {len(features)} regions into {output_dir.relative_to(root)} "
        f"for {len(QUIZZES)} quizzes."
    )


if __name__ == "__main__":
    main()
