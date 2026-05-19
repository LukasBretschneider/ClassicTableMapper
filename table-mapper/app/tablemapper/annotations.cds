using TableMapperService as service from '../../srv/tablemapper-service';

// ── List Report: MappingOverview ─────────────────────────────────────────────
annotate service.MappingOverview with @(
    UI.SelectionFields: [baseTableName, successorEntityName, baseTableReleaseState, baseTableOfficialSuccessor, successorEntityIsReleased],
    UI.PresentationVariant: {
        GroupBy: [ baseTableName ],
        SortOrder: [
            { Property: coveragePercent, Descending: true }
        ],
        Visualizations: [ '@UI.LineItem' ]
    },
    UI.LineItem: [
        { Value: baseTableName,                 Label: 'Base Table'          },
        { Value: baseTableDescription,          Label: 'Description'         },
        { Value: baseTableApplicationComponent, Label: 'App. Component'      },
        { Value: successorEntityName,           Label: 'Successor Entity'    },
        {
            Value: successorEntityIsReleased,
            Label: 'Released',
            Criticality: successorEntityReleaseCriticality,
            CriticalityRepresentation: #WithIcon
        },
        { Value: successorEntityReleaseContract, Label: 'Release Contract'   },
        { Value: successorEntityC1Status,        Label: 'C1 Status'          },
        { Value: baseTableFieldCount,           Label: 'Base Fields'         },
        { Value: mappedFieldCount,              Label: 'Mapped Fields'       },
        {
            Value: coveragePercent,
            Label: 'Coverage (%)',
            Criticality: coverageCriticality,
            CriticalityRepresentation: #WithIcon
        }
    ],
    UI.HeaderInfo: {
        TypeName: 'Mapping',
        TypeNamePlural: 'Mappings',
        Title: { Value: baseTableName }
    }
);

annotate service.MappingOverview with {
    coveragePercent @(
        UI.DataPoint: {
            Value: coveragePercent,
            Visualization: #Progress,
            TargetValue: 100
        }
    );
}

// ── Object Page: MappingOverview ─────────────────────────────────────────────
annotate service.MappingOverview with @(
    UI.Facets: [
        {
            $Type : 'UI.CollectionFacet',
            ID    : 'Overview',
            Label : 'Overview',
            Facets: [
                {
                    $Type : 'UI.ReferenceFacet',
                    Target: '@UI.FieldGroup#General',
                    Label : 'General Information'
                },
                {
                    $Type : 'UI.ReferenceFacet',
                    Target: '@UI.DataPoint#Coverage',
                    Label : 'Coverage'
                }
            ]
        },
        {
            $Type : 'UI.ReferenceFacet',
            Target: 'mappedFields/@UI.LineItem',
            Label : 'Mapped Fields'
        },
        {
            $Type : 'UI.ReferenceFacet',
            Target: 'baseFields/@UI.LineItem',
            Label : 'Base Table Fields'
        },
        {
            $Type : 'UI.ReferenceFacet',
            Target: 'successorFields/@UI.LineItem',
            Label : 'Successor-Only Fields'
        }
    ],
    UI.FieldGroup#General: {
        Data: [
            { Value: baseTableName,                      Label: 'Base Table'                  },
            { Value: baseTableDescription,               Label: 'Base Table Description'      },
            { Value: baseTableApplicationComponent,      Label: 'Base Table App. Component'   },
            { Value: baseTableReleaseState,              Label: 'Release State'               },
            { Value: baseTableOfficialSuccessor,         Label: 'Official Successor'          },
            { Value: successorEntityName,                Label: 'Successor Entity'             },
            { Value: successorEntityDescription,         Label: 'Successor Description'        },
            { Value: successorEntityApplicationComponent, Label: 'Successor App. Component'   },
            {
                Value: successorEntityIsReleased,
                Label: 'Released',
                Criticality: successorEntityReleaseCriticality,
                CriticalityRepresentation: #WithIcon
            },
            { Value: successorEntityReleaseContract,     Label: 'Release Contract'             },
            { Value: successorEntityC1Status,            Label: 'C1 Status'                    },
            { Value: baseTableFieldCount,                Label: 'Total Base Fields'            },
            { Value: successorEntityFieldCount,          Label: 'Total Successor Fields'       },
            { Value: mappedFieldCount,                   Label: 'Mapped Fields'                },
            { Value: coveragePercent,                    Label: 'Coverage (%)'                 }
        ]
    },
    UI.DataPoint#Coverage: {
        Value: coveragePercent,
        Visualization: #Progress,
        TargetValue: 100,
        Title: 'Field Coverage',
        Criticality: coverageCriticality
    }
);

// ── MappedFields sub-table ────────────────────────────────────────────────────
annotate service.MappedFields with @(
    UI.LineItem: [
        { Value: baseField,      Label: 'Base Table Field' },
        { Value: successorField, Label: 'Successor Field'  }
    ]
);

// ── BaseFieldStatus sub-table ─────────────────────────────────────────────────
annotate service.BaseFieldStatus with @(
    UI.LineItem: [
        { Value: fieldName,      Label: 'Field Name'  },
        { Value: description,    Label: 'Description' },
        { Value: isMapped,       Label: 'Mapped?'     },
        { Value: successorField, Label: 'Maps to'     }
    ]
);

// ── SuccessorOnlyFields sub-table ─────────────────────────────────────────────
annotate service.SuccessorOnlyFields with @(
    UI.LineItem: [
        { Value: fieldName,   Label: 'Successor Field' },
        { Value: description, Label: 'Description'     },
        { Value: isMapped,    Label: 'Has Base Match?' }
    ]
);
