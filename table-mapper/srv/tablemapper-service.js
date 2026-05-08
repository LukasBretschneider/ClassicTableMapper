const cds = require('@sap/cds');

module.exports = class TableMapperService extends cds.ApplicationService {

    async init() {
        const db = await cds.connect.to('db');
        const { TableMapping, BaseField, SuccessorField } = db.entities('tablemapper');

        // ── MappingOverview ──────────────────────────────────────────────────
        this.on('READ', 'MappingOverview', async (req) => {
            // req.params[0] is set when navigating to a single object page entry
            const keyFilter = req.params?.[0] ?? {};
            const filters   = parseEqFilters(req.query.SELECT?.where ?? []);
            const baseTableName       = keyFilter.baseTableName       ?? filters.baseTableName;
            const successorEntityName = keyFilter.successorEntityName ?? filters.successorEntityName;

            const where = {};
            if (baseTableName)       where.baseTable_name       = baseTableName;
            if (successorEntityName) where.successorEntity_name = successorEntityName;

            const query = SELECT.from(TableMapping)
                .columns(
                    'baseTable_name                              as baseTableName',
                    'baseTable.description                       as baseTableDescription',
                    'baseTable.applicationComponent              as baseTableApplicationComponent',
                    'baseTable.releaseState                      as baseTableReleaseState',
                    'baseTable.officialSuccessor_name            as baseTableOfficialSuccessor',
                    'successorEntity_name                        as successorEntityName',
                    'successorEntity.description                 as successorEntityDescription',
                    'successorEntity.applicationComponent        as successorEntityApplicationComponent',
                    'successorEntity.isReleased                  as successorEntityIsReleased',
                    'successorEntity.releaseContract             as successorEntityReleaseContract',
                    'successorEntity.c1Status                    as successorEntityC1Status',
                    'count(*) as mappedFieldCount'
                )
                .groupBy(
                    'baseTable_name', 'baseTable.description', 'baseTable.applicationComponent',
                    'baseTable.releaseState', 'baseTable.officialSuccessor_name',
                    'successorEntity_name', 'successorEntity.description', 'successorEntity.applicationComponent',
                    'successorEntity.isReleased', 'successorEntity.releaseContract', 'successorEntity.c1Status'
                );

            if (Object.keys(where).length) query.where(where);

            const [pairs, baseFieldCounts, successorFieldCounts] = await Promise.all([
                db.run(query),
                db.run(SELECT.from(BaseField).columns('baseTable_name as tableName', 'count(*) as cnt').groupBy('baseTable_name')),
                db.run(SELECT.from(SuccessorField).columns('successorEntity_name as entityName', 'count(*) as cnt').groupBy('successorEntity_name'))
            ]);

            const baseCountMap      = Object.fromEntries(baseFieldCounts.map(r => [r.tableName, r.cnt]));
            const successorCountMap = Object.fromEntries(successorFieldCounts.map(r => [r.entityName, r.cnt]));

            const result = pairs.map(p => {
                const baseTableFieldCount       = baseCountMap[p.baseTableName]      ?? 0;
                const successorEntityFieldCount = successorCountMap[p.successorEntityName] ?? 0;
                const pct = baseTableFieldCount > 0
                    ? Math.round((p.mappedFieldCount / baseTableFieldCount) * 10000) / 100
                    : 0;
                return {
                    ...p,
                    baseTableFieldCount,
                    successorEntityFieldCount,
                    coveragePercent: pct,
                    coverageCriticality: pct < 10 ? 1 : pct < 50 ? 2 : 3,
                    successorEntityReleaseCriticality: p.successorEntityIsReleased ? 3 : 1
                };
            });

            // Single-entity read (object page) — return the object, not an array
            if (baseTableName && successorEntityName) return result[0] ?? null;
            return result;
        });

        // ── MappedFields ─────────────────────────────────────────────────────
        this.on('READ', 'MappedFields', async (req) => {
            // req.params contains parent key predicates when navigating via composition
            const parentKeys = req.params?.[0] ?? {};
            const filters    = parseEqFilters(req.query.SELECT?.where ?? []);
            const baseTableName       = parentKeys.baseTableName       ?? filters.baseTableName;
            const successorEntityName = parentKeys.successorEntityName ?? filters.successorEntityName;

            const where = {};
            if (baseTableName)       where.baseTable_name       = baseTableName;
            if (successorEntityName) where.successorEntity_name = successorEntityName;

            const rows = await db.run(
                SELECT.from(TableMapping)
                    .columns('baseTable_name as baseTableName', 'successorEntity_name as successorEntityName',
                             'baseField', 'successorField')
                    .where(where)
            );
            return rows;
        });

        // ── BaseFieldStatus ──────────────────────────────────────────────────
        this.on('READ', 'BaseFieldStatus', async (req) => {
            const parentKeys = req.params?.[0] ?? {};
            const filters    = parseEqFilters(req.query.SELECT?.where ?? []);
            const baseTableName   = parentKeys.baseTableName   ?? filters.baseTableName;
            const successorEntity = parentKeys.successorEntityName ?? filters.successorEntity;

            const fields = await db.run(
                SELECT.from(BaseField)
                    .columns('baseTable_name as baseTableName', 'name as fieldName', 'description')
                    .where({ baseTable_name: baseTableName })
            );

            const mappings = baseTableName
                ? await db.run(
                    SELECT.from(TableMapping)
                        .columns('baseField', 'successorField')
                        .where({ baseTable_name: baseTableName, ...(successorEntity ? { successorEntity_name: successorEntity } : {}) })
                )
                : [];

            const mappingMap = {};
            for (const m of mappings) mappingMap[m.baseField] = m.successorField;

            return fields.map(f => ({
                ...f,
                isMapped: f.fieldName in mappingMap,
                successorField: mappingMap[f.fieldName] ?? null,
                successorEntity: successorEntity ?? null
            }));
        });

        // ── SuccessorOnlyFields ──────────────────────────────────────────────
        this.on('READ', 'SuccessorOnlyFields', async (req) => {
            const parentKeys = req.params?.[0] ?? {};
            const filters    = parseEqFilters(req.query.SELECT?.where ?? []);
            const successorEntityName = parentKeys.successorEntityName ?? filters.successorEntityName;
            const baseTableName       = parentKeys.baseTableName       ?? filters.baseTableName;

            const fields = await db.run(
                SELECT.from(SuccessorField)
                    .columns('successorEntity_name as successorEntityName', 'name as fieldName', 'description')
                    .where({ successorEntity_name: successorEntityName })
            );

            const mappings = successorEntityName
                ? await db.run(
                    SELECT.from(TableMapping)
                        .columns('successorField')
                        .where({ successorEntity_name: successorEntityName, ...(baseTableName ? { baseTable_name: baseTableName } : {}) })
                )
                : [];

            const mappedSet = new Set(mappings.map(m => m.successorField));

            return fields.map(f => ({
                ...f,
                isMapped: mappedSet.has(f.fieldName)
            }));
        });

        // ── uploadBaseTables ─────────────────────────────────────────────────
        // CSV: name, description, applicationComponent, releaseState, officialSuccessor
        this.on('uploadBaseTables', async (req) => {
            const { BaseTable } = db.entities('tablemapper');
            const rows = parseCsv(req.data.csv);
            if (!rows.length) return req.error(400, 'CSV is empty or missing header row');
            let count = 0;
            for (const row of rows) {
                if (!row.name) continue;
                await UPSERT.into(BaseTable).entries({
                    name:                      row.name,
                    description:               row.description ?? '',
                    applicationComponent:      row.applicationComponent ?? '',
                    releaseState:              row.releaseState ?? 'none',
                    officialSuccessor_name:    row.officialSuccessor || null
                });
                count++;
            }
            return `Upserted ${count} base table(s)`;
        });

        // ── uploadSuccessorEntities ──────────────────────────────────────────
        // CSV: name, description
        this.on('uploadSuccessorEntities', async (req) => {
            const { SuccessorEntity } = db.entities('tablemapper');
            const rows = parseCsv(req.data.csv);
            if (!rows.length) return req.error(400, 'CSV is empty or missing header row');
            let count = 0;
            for (const row of rows) {
                if (!row.name) continue;
                await UPSERT.into(SuccessorEntity).entries({
                    name:                 row.name,
                    description:          row.description ?? '',
                    applicationComponent: row.applicationComponent ?? '',
                    isReleased:           row.isReleased === 'true' || row.isReleased === 'Yes',
                    releaseContract:      row.releaseContract ?? 'None',
                    c1Status:             row.c1Status ?? ''
                });
                count++;
            }
            return `Upserted ${count} successor entity/entities`;
        });

        // ── uploadMappings ───────────────────────────────────────────────────
        // CSV: baseTable, baseField, entity, entityField
        this.on('uploadMappings', async (req) => {
            const rows = parseCsv(req.data.csv);
            if (!rows.length) return req.error(400, 'CSV is empty or missing header row');
            let count = 0;
            for (const row of rows) {
                if (!row.baseTable || !row.baseField || !row.entity) continue;
                await UPSERT.into(TableMapping).entries({
                    baseTable_name:       row.baseTable,
                    successorEntity_name: row.entity,
                    baseField:            row.baseField,
                    successorField:       row.entityField ?? ''
                });
                count++;
            }
            return `Upserted ${count} mapping(s)`;
        });

        return super.init();
    }
};

// ── CSV parser ────────────────────────────────────────────────────────────────
// Handles Buffer or string input, returns array of objects keyed by header row
function parseCsv(raw) {
    const text = Buffer.isBuffer(raw) ? raw.toString('utf8') : String(raw);
    const lines = text.split(/\r?\n/).map(l => l.trim()).filter(Boolean);
    if (lines.length < 2) return [];
    const headers = lines[0].split(',').map(h => h.trim());
    return lines.slice(1).map(line => {
        const values = line.split(',').map(v => v.trim());
        return Object.fromEntries(headers.map((h, i) => [h, values[i] ?? '']));
    });
}

// Helper: extract simple key=value equality filters from a CDS where clause array
function parseEqFilters(where) {
    const result = {};
    for (let i = 0; i < where.length; i++) {
        const token = where[i];
        if (typeof token === 'object' && token.ref && where[i + 1] === '=' && where[i + 2]) {
            result[token.ref[token.ref.length - 1]] = where[i + 2].val ?? where[i + 2];
            i += 2;
        }
    }
    return result;
}
