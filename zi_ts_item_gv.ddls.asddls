@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption view for timesheet item'
@Metadata.ignorePropagatedAnnotations: true
define view entity zi_ts_item_gv
  as select from zrap_ts_item
  association        to parent zi_ts_hdr_gv as _tsheader on  $projection.TimeId = _tsheader.TimeId
                                                         and $projection.EmpId  = _tsheader.EmpId
  association [0..1] to zrap_emp_gv         as _emp      on  $projection.EmpId = _emp.emp_id
  association        to zi_reject           as _rej      on  _rej.TimeId = $projection.TimeId
                                                         and _rej.EmpId  = $projection.EmpId
                                                         and _rej.Status = $projection.Status
{
  key time_id                       as TimeId,
  key emp_id                        as EmpId,
  key item_no                       as ItemNo,
      zdate                         as Zdate,
      pro_id                        as ProId,
      task                          as Task,
      checkin_time                  as Checkin_time,
      checkout_time                 as checkout_time,
      zhours                        as Zhours,
      status                        as Status,
      case status
      when 'Rejected' then 1
      when 'Approved' then 3
      else 2 end                    as status_cri,
      _tsheader.manager_id,
      _tsheader.isapprejhide,
      _tsheader.ImageUrl            as image_url,
      _rej.Reason,
      cast ( case when _rej.Reason is null then 'X'
      else '' end as abap_boolean ) as isrejhide,
      _emp,
      _tsheader // Make association public
}
