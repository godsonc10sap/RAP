@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Project details'
@Metadata.ignorePropagatedAnnotations: true
define root view entity zi_proj_id_gv
  as select from zrap_project_gv as pro
  association [1] to zrap_cus_gv as _cus on _cus.cus_id = $projection.CusId
{
 key pro.pro_id as ProId,
 key pro.emp_id as EmpId,
 pro.pro_name as ProName,
 pro.cus_id as CusId,
 pro.status as Status,
 _cus.cus_name as Customername
}
