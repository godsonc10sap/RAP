@EndUserText.label: 'Popup for user login'
define abstract entity Zi_user_details_gv
{
  @EndUserText.label: 'Email ID'
  @ObjectModel.mandatory: true
  userid   : abap.char( 50 );
  @ObjectModel.mandatory: true
  Password : abap.char(20);

}
