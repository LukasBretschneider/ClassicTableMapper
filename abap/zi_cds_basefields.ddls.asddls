@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Base Fields for Table Mapper'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory:   #M,
  dataClass:      #MASTER
}
define view entity ZI_CDS_BASEFIELDS
  as select distinct from DD03L as FieldDef
    inner join ZI_CDS_MAPPING as Mapping
      on  Mapping.baseTable_name = FieldDef.tabname
    left outer join DD04T as FieldText
      on  FieldText.rollname    = FieldDef.rollname
      and FieldText.ddlanguage  = 'E'
  where FieldDef.as4local = 'A'
{
      // CSV target field: baseTable_name (FK to ZI_CDS_BASETABLES)
  key FieldDef.tabname           as baseTable_name,

      // CSV target field: name
  key FieldDef.fieldname         as name,

      // CSV target field: description
      FieldText.ddtext            as description
}
