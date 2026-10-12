@EndUserText.label: 'Abstract for Time - off'
define abstract entity ZI_time_off_gv
{
  @EndUserText.label: 'Leave Type   '
  @Consumption.valueHelpDefinition: [
    {
      entity: {
        name    : 'ZI_LEAVE_TYPE',
        element : 'Description'
      } }
  ]
  timeoff_type : abap.char(50);
  @EndUserText.label: 'Start Date'
  @ObjectModel.mandatory: true
  from_date    : datum;
  @EndUserText.label: 'Period'
  @ObjectModel.mandatory: true
  @Consumption.valueHelpDefinition: [
    {
      entity: {
        name    : 'Zi_period',
        element : 'Period'
      } }
  ]
  Period       : abap.char( 10 );

}
