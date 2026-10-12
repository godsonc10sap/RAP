@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Consumption view for timesheet header'

@Metadata.ignorePropagatedAnnotations: true

define root view entity zi_ts_hdr_gv

  as select from zrap_ts_hrd as header
  composition [0..*] of zi_ts_item_gv as _tsitem

  association        to zrap_emp_gv          as _employee on  _employee.emp_id = $projection.EmpId
  association [1]    to zrap_emp_gv      as _manger       on  _manger.emp_id = $projection.manager_id
  association [1]    to zrap_para_id     as _login        on  _login.uname = $session.user
                                                          and _login.zdate = $session.system_date

  composition [0..*] of zi_appr_gv    as _appr
  composition [0..*] of ZI_EXPENSES as _expenses
  composition [*] of Zi_leave_history as _leavehistory
  association [1]    to zi_appr_count_gv as _cnt          on  _cnt.TimeId = $projection.TimeId
                                                          and _cnt.EmpId  = $projection.EmpId
  association [1]    to zrap_role_gv     as _role         on  _role.role_id = $projection.role_id
  association [0..*] to zi_proj_id_gv as _pro             on  _pro.EmpId = $projection.EmpId
  association [1]    to Zi_login_user    as _login1       on  _login1.EmpId = $projection.EmpId
  association [1]    to zrap_emp_gv      as _emp          on  _emp.manager_id = $projection.emp_id1
  association [1]    to ZI_LEAVE_BAL     as _leavebal     on  _leavebal.EmpId = $projection.EmpId
  association [1]    to ZI_PAYALIP       as _payslip      on  _payslip.TimeId = $projection.TimeId
                                                          and _payslip.EmpId  = $projection.EmpId






{
  key header.time_id                            as TimeId,
  key header.emp_id                             as EmpId,

      header.zmonth                             as Zmonth,
      case header.zmonth
      when 'January'  then '01'
      when 'February' then '02'
      when 'March'    then '03'
      when 'April'    then '04'
      when 'May'      then '05'
      when 'June'     then '06'
      when 'July'     then '07'
      when 'August'   then '08'
      when 'September' then '09'
      when 'October'  then '10'
      when 'November' then '11'
      when 'December' then '12'
      end                                       as curr_month,
      header.start_date                         as StartDate,
      header.end_date                           as EndDate,
      header.status                             as Status,
      @Semantics.largeObject: {
         mimeType: 'MineType',
         fileName: 'Filename',
         contentDispositionPreference: #ATTACHMENT
      }
      header.attchement                         as Attchement,

      @Semantics.mimeType: true
      header.mine_type                          as MineType,

      header.filename                           as Filename,

      _cnt.TotalAppr                            as appr,
      _cnt.ApprProcess                          as pappr,
      _cnt.workingday,
      case
      when _cnt.TotalAppr = _cnt.ApprProcess
      then 3
      when _cnt.ApprProcess > 0
      then 2
      else 2 end                                as pro_cri,
      case header.status
        when 'Approved'   then 3
        when 'Rejected' then 1
        else 2
      end                                       as criticality,

      cast( case
       when header.status = 'Created'  then ''
       else 'X' end as abap_boolean )           as isedithide,

      header.total_hours                        as TotalHours,

      _employee.emp_name,
      _employee.manager_id,
      _manger,
      _employee.email,
      _employee.role_id,
      _employee.designation,
      _role,
      _login,
      cast( case
       when _login.para_id = _employee.email and header.status <> 'Approved' then ''
       else 'X' end  as abap_boolean )          as isuserhide,
      cast( case
      when _login.para_id = _employee.email  then 'X'
      when _login.para_id = 'finance@vrikshamsofttech.com' then 'X'
      when header.status = 'Approved' then 'X'
      else '' end  as abap_boolean )            as isapprejhide,
      cast ( case when header.filename is not initial then ''
                 else 'X' end as abap_boolean ) as isattachementhide,
      _tsitem,
      _pro,
      @Semantics.imageUrl: true
      cast(
      _employee.image_url
      as abap.char(255)
      )                                         as ImageUrl,
      _leavehistory,
      _appr,
      _login1.EmpId                             as emp_id1,
      _leavebal,
      @Semantics.largeObject: {
      mimeType: 'P_MineType',
      fileName: 'P_Filename',
      contentDispositionPreference: #ATTACHMENT
      }
      _payslip.P_Attchement,
      _payslip.P_Filename,
      cast( case
      when _payslip.P_Filename is null  then 'X'
      else '' end as abap_boolean )            as ispayatthide,
      _expenses,
      _payslip.P_MineType
      //      _emp

}
where
  (
         _login.uname   = $session.user
    and(
         _login.para_id = _employee.email
      or(
         emp_id         = _login1.EmpId
      )
    )
  )
  or(
         _login.uname   = $session.user
    and  _login.para_id = 'finance@vrikshamsofttech.com'
    and(
         status         = 'HR Approved'
      or status         = 'Manager Approved'
      or status         = 'Approved'
      or status         = 'Rejected'
    )
  )
