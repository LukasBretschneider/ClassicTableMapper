@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Successor Entities for Table Mapper'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory:   #S,
  dataClass:      #MASTER
}
define view entity ZI_CDS_SUCC_ENTITIES
  as select distinct from ZI_CDS_MAPPING as Mapping
    left outer join ZI_CDSFIELDINDEX as FieldIndex
      on FieldIndex.EntityName = Mapping.successorEntity_name
    join DDL_OBJECT_NAMES as ObjNames
      on ObjNames.CDS_DDL = Mapping.successorEntity_name and
         ObjNames.TEXT_LANGUAGE = 'E'
{
      // CSV target field: name
  key Mapping.successorEntity_name              as name,

      // CSV target field: description
      ObjNames.TEXT                           as description,

      // CSV target field: applicationComponent
      FieldIndex.ApplicationComponentName           as applicationComponent,

      // CSV target field: isReleased  (true when ReleaseState = 'RELEASED')
      case FieldIndex.ReleaseState
        when 'RELEASED' then 'true'
        else                 'false'
      end                                       as isReleased,

      // CSV target field: releaseContract  (C0, C1, etc.)
      FieldIndex.CompatibilityContract          as releaseContract,

      // CSV target field: c1Status  (derived from use-flags)
      case
        when FieldIndex.UseInKeyUserApps      = 'X'
         and FieldIndex.UseInSapCloudPlatform = 'X' then 'Both'
        when FieldIndex.UseInKeyUserApps      = 'X' then 'Key-User'
        when FieldIndex.UseInSapCloudPlatform = 'X' then 'Developer'
        else                                              ''
      end                                       as c1Status
}
