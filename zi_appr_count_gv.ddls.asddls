@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Approver Count'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity zi_appr_count_gv
  as select from zrap_ts_hrd   as hdr

    inner join   zrap_appr_gv  as appr on appr.time_id = hdr.time_id
    association to   zi_item_count as item on  item.TimeId = hdr.time_id
                                       and item.EmpId  = hdr.emp_id
{
  key hdr.time_id as TimeId,
  key hdr.emp_id  as EmpId,
      @EndUserText.label: 'Approved Status'
      count(*)    as TotalAppr,
      @EndUserText.label: 'Approved Status'
      sum(
        case
          when appr.status = 'Approved'
          then 1
          else 0
        end
      )           as ApprProcess,
      item.workingday
}
group by
  hdr.time_id,
  hdr.emp_id,
  item.workingday
