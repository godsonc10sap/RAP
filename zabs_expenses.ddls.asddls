@EndUserText.label: 'EXPENSES'
define abstract entity ZABS_EXPENSES
{
  @EndUserText.label: 'Category'
  category      : abap.char( 50 );
  @EndUserText.label: 'Expense Date'
  ex_date       : datum;
  @EndUserText.label: 'Total Amount'
  Total         : zrap_dec;
  @EndUserText.label: 'Employee Paid'
  employee_paid : abap_boolean;


}
