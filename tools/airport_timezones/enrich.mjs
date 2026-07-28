// One-off build-time enrichment: adds an IANA `timezone` column to
// assets/data/airports.csv by resolving each airport's lat/lon against the
// official timezone-boundary polygons (geo-tz, fully offline — no API).
// Re-run whenever airports.csv is regenerated:
//   cd tools/airport_timezones && npm install && node enrich.mjs
import {readFileSync, writeFileSync} from "node:fs";
import {fileURLToPath} from "node:url";
import {parse} from "csv-parse/sync";
import {stringify} from "csv-stringify/sync";
// The `all` dataset keeps canonical zone names (America/La_Paz), unlike the
// default "now" dataset which merges zones with identical rules since 1970
// (it would label La Paz as America/Puerto_Rico).
import {find} from "geo-tz/all";

const csvPath = fileURLToPath(
  new URL("../../assets/data/airports.csv", import.meta.url),
);
const rows = parse(readFileSync(csvPath, "utf8"));
const header = rows[0];
let tzIndex = header.indexOf("timezone");
if (tzIndex === -1) {
  tzIndex = header.length;
  header.push("timezone");
}

let filled = 0;
const missing = [];
for (let i = 1; i < rows.length; i++) {
  const row = rows[i];
  while (row.length <= tzIndex) row.push("");
  const lat = Number.parseFloat(row[4]);
  const lon = Number.parseFloat(row[5]);
  const zones =
    Number.isFinite(lat) && Number.isFinite(lon) ? find(lat, lon) : [];
  row[tzIndex] = zones[0] ?? "";
  if (row[tzIndex]) {
    filled++;
  } else {
    missing.push(`${row[1]} ${row[3]}`);
  }
}

writeFileSync(csvPath, stringify(rows));
console.log(`timezone filled for ${filled}/${rows.length - 1} airports`);
if (missing.length) console.log(`missing:\n${missing.join("\n")}`);
