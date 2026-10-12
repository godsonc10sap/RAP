@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Project details'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZC_PROJECT_GV
  provider contract transactional_query
  as projection on zi_proj_id_gv
{
      @UI.lineItem: [{ position: 10 , label: 'Project ID' }]

  key ProId,
  key EmpId,
      @UI.lineItem: [{ position: 20 , label: 'Project Name'  }]

      ProName,
      CusId,
      Status,
      Customername
}
