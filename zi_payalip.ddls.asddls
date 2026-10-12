@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachement  for Payslip'
define view entity ZI_PAYALIP
  as select from zrap_attach_gv
{
  key time_id    as TimeId,
  key emp_id     as EmpId,
      attchement as P_Attchement,
      @Semantics.mimeType: true
      mine_type  as P_MineType,
      filename   as P_Filename
}
