@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'EXPENSES'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_EXPENSES
  as select from zrap_expenses
  association to parent zi_ts_hdr_gv as _tsheader on  $projection.Timeid = _tsheader.TimeId
                                                  and $projection.EmpId  = _tsheader.EmpId
{
  key timeid      as Timeid,
  key emp_id      as EmpId,
  key ex_date     as ExDate,
  key category    as Category,
      paid_by     as PaidBy,
      total_amt   as TotalAmt,
      status      as Status,
      description as Description,
      _tsheader
}
