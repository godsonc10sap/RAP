@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'EXPENSES'
@Metadata.ignorePropagatedAnnotations: true
@UI.headerInfo: {
    typeName: 'Expense',
    typeNamePlural: 'Expenses',
    title: {
        type: #STANDARD,
        value: 'Description'
    },
    description: {
        type: #STANDARD,
        value: 'EmpId'
    }
}
define view entity ZC_EXPENSES
  as projection on ZI_EXPENSES
{
      @UI.facet: [
          {
              id: 'ExpenseDetails',
              type: #FIELDGROUP_REFERENCE,
              label: 'Expense Details',
              targetQualifier: 'ExpenseDetails',
              position: 10
          }
      ]
      @UI.lineItem: [
        { type: #FOR_ACTION, dataAction: 'expenses_approve', position: 10, label: 'Approve Expense' },
        { type: #FOR_ACTION, dataAction: 'expenses_reject', position: 20, label: 'Reject Expense' }
      ]
  key Timeid,

      @UI.lineItem: [
          { position: 20, label: 'Employee ID' }
      ]
      @UI.fieldGroup: [
          {
              qualifier: 'ExpenseDetails',
              position: 20,
              label: 'Employee ID'
          }
      ]
  key EmpId,

      @UI.lineItem: [
          { position: 30, label: 'Expense Date' }
      ]
      @UI.fieldGroup: [
          {
              qualifier: 'ExpenseDetails',
              position: 30,
              label: 'Expense Date'
          }
      ]
  key ExDate,

      @UI.lineItem: [
          { position: 40, label: 'Category' }
      ]
      @UI.fieldGroup: [
          {
              qualifier: 'ExpenseDetails',
              position: 40,
              label: 'Category'
          }
      ]
  key Category,

      @UI.lineItem: [
          { position: 50, label: 'Paid By' }
      ]
      @UI.fieldGroup: [
          {
              qualifier: 'ExpenseDetails',
              position: 50,
              label: 'Paid By'
          }
      ]
      PaidBy,

      @UI.lineItem: [
          { position: 60, label: 'Total Amount' }
      ]
      @UI.fieldGroup: [
          {
              qualifier: 'ExpenseDetails',
              position: 60,
              label: 'Total Amount'
          }
      ]
      TotalAmt,

      @UI.lineItem: [
          { position: 70, label: 'Status' }
      ]
      @UI.fieldGroup: [
          {
              qualifier: 'ExpenseDetails',
              position: 70,
              label: 'Status'
          }
      ]
      Status,
      @UI.fieldGroup: [
          {
              qualifier: 'ExpenseDetails',
              position: 80,
              label: 'Description'
          }
      ]
      Description,

      _tsheader : redirected to parent zc_ts_hdr_gv
}
