@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Base Tables for Table Mapper'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory:   #S,
  dataClass:      #MASTER
}
define view entity ZI_CDS_BASETABLES
  as select distinct from ZI_CDSFIELDINDEX as Mapping
    left outer join dd02l as TableDef
      on  TableDef.tabname  = Mapping.BaseObject
      and TableDef.as4local = 'A'
    left outer join dd02t as TableText
      on  TableText.tabname    = Mapping.BaseObject
      and TableText.ddlanguage = 'E'
    left outer join ARS_RUNTIME_API_STATE as ApiState
      on  ApiState.object_name = Mapping.BaseObject
      and ApiState.object_type = 'TABL'
    left outer join tadir as ObjDir
      on  ObjDir.object   = 'TABL'
      and ObjDir.obj_name = Mapping.BaseObject
    left outer join tdevc as Package
      on  Package.devclass = ObjDir.devclass
    left outer join df14l as AppComp
      on  AppComp.fctr_id = Package.component
{
      // CSV target field: name
  key Mapping.BaseObject                        as name,

      // CSV target field: description
      TableText.ddtext                          as description,

      // CSV target field: applicationComponent  (e.g. "MM-PUR")
      AppComp.ps_posid                          as applicationComponent,

      // CSV target field: releaseState
      coalesce( ApiState.release_state, 'none' ) as releaseState,

      // CSV target field: officialSuccessor_name
      ApiState.successor_object_name             as officialSuccessor_name
}
