@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Reject'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity zi_reject as select from zrap_reject
{
    key time_id as TimeId,
    key emp_id as EmpId,
    status as Status,
    @Semantics.text: true
    reason as Reason
}
