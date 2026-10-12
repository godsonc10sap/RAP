@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Approver details'
//@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_appr_gv
  as projection on zi_appr_gv
{
    
           
  key ApprId,
  key TimeId,
  key EmpId,
  key apprnum,     
//      @ObjectModel.text.element: [ 'Role' ]
      Approver,    
      @ObjectModel.text.element: [ 'Reason' ]
      @UI.textArrangement: #TEXT_LAST
      Status,  
      Zdate,
      status_cri,
      _role.Role,
      ApprovalComments,
      Dateofapproval,
      Timeofapproval,
      @Semantics.imageUrl: true
      ImageUrl,
      _Header : redirected to parent zc_ts_hdr_gv
}
