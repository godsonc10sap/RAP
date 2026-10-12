@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Composite view for timesheet item'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: [ 'EmpId' ]
define view entity ZC_ts_item_gv as projection on zi_ts_item_gv
{
    key TimeId,
    key EmpId,
    key ItemNo,
    Zdate,
    @Consumption.valueHelpDefinition: [
  {
    entity: {
      name: 'zi_project_gv',
      element: 'ProId'
    } }
]
    ProId,
    Task,
    Zhours,
    Checkin_time,
    checkout_time,
    manager_id,
    Status,
    status_cri,
    isapprejhide,
    image_url,
    Reason,
    isrejhide,
    _tsheader.isuserhide,
    _emp.emp_name,
    /* Associations */
    _tsheader : redirected to parent zc_ts_hdr_gv
}
