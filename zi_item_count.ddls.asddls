@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Item Count'
@Metadata.ignorePropagatedAnnotations: true
define view entity zi_item_count
   as select from zrap_ts_hrd   as hdr
   inner join zrap_ts_item as item on  item.time_id = hdr.time_id
////                                       and item.emp_id  = hdr.emp_id
{
  key hdr.time_id                   as TimeId,
  key hdr.emp_id                    as EmpId,
      count(*) as workingday
}
group by
  hdr.time_id,
  hdr.emp_id
