@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Leave History'
@Metadata.ignorePropagatedAnnotations: true
@UI.presentationVariant: [
  {
    groupBy: [ 'LeaveType' ]
  }
]
define view entity ZC_leave_history
  as projection on Zi_leave_history
{
      @UI.facet: [{ type: #FIELDGROUP_REFERENCE, purpose: #HEADER, label: 'Period',importance: #HIGH,targetQualifier: 'F1',position: 30 },
                  { type: #DATAPOINT_REFERENCE, purpose: #HEADER, importance: #HIGH,targetQualifier: 'D1',position: 10 },
                  { type: #DATAPOINT_REFERENCE, purpose: #HEADER, importance: #HIGH,targetQualifier: 'D2',position: 20 }]
  key Timeid,
      @UI.fieldGroup: [{ position: 10 , label: 'Employee ID',qualifier: 'F1'  }]
  key EmpId,
      @UI.lineItem: [{ position: 10 , label: 'Leave Type' },
                   { type: #FOR_ACTION, dataAction: 'Approve_leave', position: 10,label: 'Approve Leave' },
                   { type: #FOR_ACTION, dataAction: 'reject_leave', position: 20,label: 'Reject Leave' }
                   ]
      @UI.dataPoint : {qualifier: 'D1', title: 'Leave Type' }
  key LeaveType,
      @UI.lineItem: [{ position: 20 , label: 'Leave Date' }]
      @UI.fieldGroup: [{ position: 10 , label: 'Leave Date',qualifier: 'F1'  }]
  key Startdate,
      @UI.fieldGroup: [{ position: 10 , label: 'Period',qualifier: 'F1'  }]
      Period,
      @UI.lineItem: [{ position: 40 , label: 'Leave Status' ,criticality: 'statuc_cri',criticalityRepresentation: #WITH_ICON }]
      @UI.dataPoint : {qualifier: 'D2', title: 'Leave Status' ,criticality: 'statuc_cri' ,criticalityRepresentation: #WITH_ICON }
      Status,
      statuc_cri,
      @Semantics.imageUrl: true
      @UI.lineItem: [{ position: 10 , label: 'Profile' ,hidden: true }]
      _leavetype.image_url,
      /* Associations */
      _tsheader : redirected to parent zc_ts_hdr_gv
}
