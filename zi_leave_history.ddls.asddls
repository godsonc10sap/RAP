@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Leave History'
@Metadata.ignorePropagatedAnnotations: true
define view entity Zi_leave_history
  as select from zrap_leave_his
  association to parent zi_ts_hdr_gv as _tsheader  on  $projection.Timeid = _tsheader.TimeId
                                                   and $projection.EmpId  = _tsheader.EmpId
  association to zrap_leave_type     as _leavetype on  $projection.LeaveType = _leavetype.description
{
  key timeid     as Timeid,
  key emp_id     as EmpId,
  key leave_type as LeaveType,
  key startdate  as Startdate,
      period     as Period,
      status     as Status,
      case status
      when 'Approved'
      then 3
      when 'Rejected'
      then 1
      else 2 end as statuc_cri,
      _leavetype,
      _tsheader // Make association public
}
