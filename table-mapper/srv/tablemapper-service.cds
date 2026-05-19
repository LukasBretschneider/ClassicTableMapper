using tablemapper as db from '../db/schema';

service TableMapperService @(path: '/tablemapper') {

    // List report entity: one row per BaseTable→SuccessorEntity combination
    @readonly
    entity MappingOverview {
        key baseTableName                  : String(30);
        key successorEntityName            : String(120);
            baseTableDescription           : String(100);
            baseTableApplicationComponent  : String(30);
            baseTableReleaseState          : String(30);
            baseTableOfficialSuccessor     : String(120);
            baseTableFieldCount            : Integer;
            successorEntityDescription          : String(100);
            successorEntityApplicationComponent : String(30);
            successorEntityIsReleased           : String(3);
            successorEntityReleaseContract      : String(4);
            successorEntityC1Status             : String(20);
            successorEntityReleaseCriticality   : Integer;  // 3=green (released), 1=red (unreleased)
            successorEntityFieldCount           : Integer;
            // computed in JS handler:
            mappedFieldCount               : Integer;
            coveragePercent                : Decimal(5,2);
            coverageCriticality            : Integer;  // 1=red, 2=yellow, 3=green
            // sub-tables on object page:
            mappedFields             : Composition of many MappedFields
                                           on mappedFields.baseTableName = baseTableName
                                          and mappedFields.successorEntityName = successorEntityName;
            baseFields               : Composition of many BaseFieldStatus
                                           on baseFields.baseTableName = baseTableName;
            successorFields          : Composition of many SuccessorOnlyFields
                                           on successorFields.successorEntityName = successorEntityName;
    }

    // Mapped base→successor field pairs
    @readonly
    entity MappedFields {
        key baseTableName       : String(30);
        key successorEntityName : String(120);
        key baseField           : String(30);
            successorField      : String(120);
    }

    // All base table fields with mapping status for a given successor
    @readonly
    entity BaseFieldStatus {
        key baseTableName   : String(30);
        key fieldName       : String(30);
            description     : String(100);
            isMapped        : Boolean;
            successorField  : String(120);
            successorEntity : String(120);
    }

    // All successor fields with flag whether they have a base table counterpart
    @readonly
    entity SuccessorOnlyFields {
        key successorEntityName : String(120);
        key fieldName           : String(120);
            description         : String(100);
            isMapped            : Boolean;
    }

    // Raw entities for data maintenance
    @cds.redirection.target
    entity BaseTables        as projection on db.BaseTable;
    @cds.redirection.target
    entity SuccessorEntities as projection on db.SuccessorEntity;
    @cds.redirection.target
    entity TableMappings     as projection on db.TableMapping;

    // Upload actions — CSV content passed as a string from the UI
    // Expected columns:
    //   uploadBaseTables:        name, description, applicationComponent, releaseState, officialSuccessor
    //   uploadSuccessorEntities: name, description, applicationComponent, isReleased, releaseContract, c1Status
    //   uploadMappings:          baseTable, baseField, entity, entityField
    action uploadBaseTables        (csv : String) returns String;
    action uploadSuccessorEntities (csv : String) returns String;
    action uploadMappings          (csv : String) returns String;
}
