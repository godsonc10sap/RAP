@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Login User'
@Metadata.ignorePropagatedAnnotations: true
define view entity Zi_login_user
  as select from zrap_emp_gv as emp
    inner join   zrap_userid as user on  user.status   = 'Login'
                                     and user.zdate    = $session.system_date
                                     and (
                                        user.emp_id    = emp.manager_id
                                        or user.emp_id = emp.report_to
                                      )

{
  key emp.emp_id     as EmpId,
      emp.emp_name   as EmpName,
      emp.role_id    as RoleId,
      emp.manager_id as ManagerId,
      emp.email      as Email,
      user.userid    as username,
      emp.report_to  as reportto,
      user.status,
      //      case
      //      when user.userid is not initial then user.userid
      //      else user1.userid end as Username,
      emp.password   as Password
}
