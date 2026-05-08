# ClassicTableMapper

ClassicTableMapper helps ABAP developers identify appropriate successor CDS Views for classic SAP database tables as part of the **Clean Core** initiative. For a given base table it shows which CDS View maps to it, how many fields are covered, and exactly which fields are (or aren't) mapped on both sides.

---

## Background

SAP's Clean Core strategy encourages replacing direct database table access in ABAP code with released CDS Views. While some tables have official successor objects, finding the right one for a given use case is non-trivial — especially when you need to know how completely a view covers the fields you actually use.

ClassicTableMapper makes this visible at a glance.

---

## Features

- **List view** — one row per Base Table → Successor Entity pair, grouped by base table (A–Z), sorted by coverage percentage within each group
- **Release status** — released successors are highlighted green, unreleased red; release contract (C0/C1) and C1 scope (Key-User / Developer / Both) are shown
- **Official successor** — each base table can carry the SAP-recommended successor for quick orientation
- **Coverage percentage** — mapped fields as a share of the base table's total field count, with a traffic-light indicator
- **Object page** — drill into any mapping to see:
  - Which base table fields are mapped and to which successor field
  - Which base table fields have no mapping (gaps)
  - Which successor fields have no base table counterpart (successor-only fields)
- **Filter bar** — filter by base table, successor entity, release state, official successor, and release status
- **Application Component (ACH)** — shown for both base tables and successor entities to identify the owning area

---

## Getting Started

### Prerequisites

- Node.js ≥ 18
- `@sap/cds-dk` installed globally (`npm install -g @sap/cds-dk`)

### Run locally

```bash
cd table-mapper
npm install
cds watch
```

The app is then available at:
```
http://localhost:4004/tablemapper/webapp/index.html
```

---

## Loading Your Own Data

Data can be provided either via **CSV deployment** (seed data in `db/data/`) or by uploading files at runtime via the upload page (`/tablemapper/webapp/upload.html`).

### CSV formats

**Base Tables** — `tablemapper-BaseTable.csv`
```
name,description,applicationComponent,releaseState,officialSuccessor_name
MARA,General Material Data,LO-MD-MM,none,I_Product
```

| Column | Values |
|---|---|
| `name` | SAP table name, e.g. `MARA` |
| `description` | Human-readable label |
| `applicationComponent` | SAP ACH component, e.g. `LO-MD-MM` |
| `releaseState` | `none` or `NOT_TO_BE_RELEASED` |
| `officialSuccessor_name` | Name of the officially recommended successor entity |

---

**Successor Entities** — `tablemapper-SuccessorEntity.csv`
```
name,description,applicationComponent,isReleased,releaseContract,c1Status
I_Product,Product basic data view,LO-MD-MM,true,C1,Both
```

| Column | Values |
|---|---|
| `name` | CDS View / entity name, e.g. `I_Product` |
| `description` | Human-readable label |
| `applicationComponent` | SAP ACH component |
| `isReleased` | `true` / `false` |
| `releaseContract` | `C0`, `C1`, or `None` |
| `c1Status` | `Key-User`, `Developer`, `Both`, or empty |

---

**Base Table Fields** — `tablemapper-BaseField.csv`
```
baseTable_name,name,description
MARA,MATNR,Material Number
```

---

**Successor Fields** — `tablemapper-SuccessorField.csv`
```
successorEntity_name,name,description
I_Product,Product,Product (Material Number)
```

---

**Field Mappings** — `tablemapper-TableMapping.csv`
```
baseTable_name,successorEntity_name,baseField,successorField
MARA,I_Product,MATNR,Product
```

---

## How to Use It

1. **Start with the list** — identify which base tables you use and check which successor entities are available. Focus on entries with a green release indicator and high coverage percentage.

2. **Check coverage** — the *Base Fields* count and *Coverage (%)* column tell you how many of the base table's fields are represented in the successor. A low percentage means the view is a partial replacement only.

3. **Drill into the object page** — click a row to see the full field breakdown:
   - **Mapped Fields** — exact base → successor field pairs you can use directly
   - **Base Table Fields** — all base fields, flagged whether they are mapped
   - **Successor-Only Fields** — fields in the CDS View that have no base table counterpart (useful additions or renamed concepts)

4. **Check the release contract** — `C1` views are stable and officially released for customer use. `C0` views are internal and subject to change. Unreleased views (red) should be avoided in productive code.

5. **Check the official successor** — if a base table has an *Official Successor* set, that is SAP's own recommendation. If your field coverage there is too low, use the list to find alternative mappings with better coverage.

---

## Project Structure

```
table-mapper/
  db/
    schema.cds          # Domain model (BaseTable, SuccessorEntity, FieldMapping, …)
    data/               # CSV seed data for local development
  srv/
    tablemapper-service.cds   # OData service definition
    tablemapper-service.js    # Custom handler (dynamic field counts, coverage calc)
  app/
    tablemapper/
      annotations.cds         # Fiori Elements UI annotations
      webapp/
        manifest.json         # App descriptor
        Component.js          # UI5 app component
        index.html            # Standalone Fiori launchpad (dev)
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | SAP CAP (`@sap/cds` v9), JavaScript |
| Database | SQLite (dev), deployable to SAP HANA |
| Frontend | SAP Fiori Elements (List Report + Object Page), UI5 1.145 |
