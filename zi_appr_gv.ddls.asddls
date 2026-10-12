@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Approver details'
@Metadata.ignorePropagatedAnnotations: true
define view entity zi_appr_gv
  as select from zrap_appr_gv
  association        to parent zi_ts_hdr_gv as _Header on  $projection.TimeId = _Header.TimeId
                                                       and $projection.EmpId  = _Header.EmpId
  association [0..1] to zrap_emp_gv         as _emp    on  _emp.emp_id = $projection.ApprId
  association [0..1] to ZI_ROLE_GV          as _role   on  _role.RoleId = $projection.role_id


{
  key   appr_id                                    as ApprId,
  key   time_id                                    as TimeId,
  key   emp_id                                     as EmpId,
  key   appr_num                                   as apprnum,
        approver                                   as Approver,
        status                                     as Status,
        case
        when status = 'Rejected' then 1
        when status = 'Approved' then 3 else 2 end as status_cri,
        zdate                                      as Zdate,
        d_apprv                                    as Dateofapproval,
        t_apprv                                    as Timeofapproval,
        a_comm                                     as ApprovalComments,
        _emp.role_id,
        _emp.image_url as ImageUrl,
        _role,
        _Header

}
