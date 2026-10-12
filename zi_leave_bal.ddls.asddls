@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Employee Leave Balance'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_LEAVE_BAL
  as select from zi_ts_hdr_gv
  association [1] to zrap_leave_bal as _leave on _leave.emp_id = $projection.EmpId
{
  key EmpId             as EmpId,
  key Zmonth            as Zmonth,
      sum( _leave.el )  as total_El,
      sum( _leave.scl ) as total_Scl,
      '5'               as leave_cri
}
where
  _leave.zmonth <= curr_month
group by
  EmpId,
  Zmonth
