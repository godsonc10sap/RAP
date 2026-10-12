@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Composite view for timesheet header'
//@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: [ 'EmpId' ]
define root view entity zc_ts_hdr_gv
  provider contract transactional_query
  as projection on zi_ts_hdr_gv
{
  key TimeId,
      //      @ObjectModel.text.element: [ 'emp_name' ]
  key EmpId,
      Zmonth,
      StartDate,
      EndDate,
      Status,
      //    @DefaultAggregation: #SUM
      TotalHours,
      emp_name,
      manager_id,
      criticality,
      pappr,
      appr,
      Attchement,
      workingday,
      Filename,
      MineType,
      pro_cri,
      email,
      _role.role,
      isedithide,
      isuserhide,
      _manger.emp_name as manger_name,
      isapprejhide,
      isattachementhide,
      @Semantics.imageUrl: true
      ImageUrl,
      designation,
      _login.uname,
      _leavebal.total_El,
      _leavebal.total_Scl,
      _leavebal.leave_cri,
      ispayatthide,
      P_Attchement,
      P_Filename,
      P_MineType,
      _pro          : redirected to ZC_PROJECT_GV,
      _tsitem       : redirected to composition child ZC_ts_item_gv,
      _leavehistory : redirected to composition child ZC_leave_history,
      _appr         : redirected to composition child ZC_appr_gv,
      _expenses : redirected to composition child ZC_EXPENSES
}
