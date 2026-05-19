@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Successor Fields for Table Mapper'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory:   #M,
  dataClass:      #MASTER
}
define view entity ZI_CDS_SUCC_FIELDS
  as select distinct from ZI_CDS_MAPPING as Mapping
{
      // CSV target field: successorEntity_name (FK to ZI_CDS_SUCC_ENTITIES)
  key Mapping.successorEntity_name              as successorEntity_name,

      // CSV target field: name
  key Mapping.successorField                    as name,

      // CSV target field: description  (no standard short text available for CDS elements)
      cast( '' as abap.char(60) )               as description
}
