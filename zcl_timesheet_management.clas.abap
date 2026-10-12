class ZCL_TIMESHEET_MANAGEMENT definition
  public
  final
  create public .

public section.

  class-methods GET_TIMESHEET
    importing
      !IV_STARTDATE type DATUM
      !IV_ENDDATE type DATUM
      !IT_ATTENDANCE type ZRAP_TB_ITEM
      !IV_EMPLOYEE type CHAR10
      !IV_BUTTON type CHAR1 optional
    exporting
      value(ET_ATT) type ZTTY_DATA
    returning
      value(RV_ATTACHEMENT) type XSTRING .
  class-methods SENT_MAIL_FOR_APPROVAL
    importing
      !IV_USER type CHAR50
      !IV_TIMEID type CHAR10
      !IV_EMPID type CHAR10
      !IV_MONTH type CHAR10
    exporting
      !EV_SEND type CHAR1 .
  class-methods SENT_MAIL_FOR_TIME_OFF
    importing
      !IS_LEAVE type ZRAP_LEAVE_HIS
      !IV_STATUS type CHAR25 optional
    exporting
      value(EV_SEND) type CHAR1 .
  class-methods SET_MEMORY_ID
    importing
      !IV_USER type CHAR50
    returning
      value(RV_SET) type CHAR1 .
  class-methods GET_MEMORY_ID
    returning
      value(RV_USER) type CHAR50 .
  class-methods GET_PAYSLIP
    importing
      !IS_HEADER type ZGO_S_PAYSLIPHEADER
      !IS_ITEM type ZGO_S_PAYSLIPITEM
    returning
      value(RV_ATTACHEMENT) type XSTRING .
protected section.
private section.

  class-methods ADD_THIN_BORDER
    importing
      !IO_STYLE type ref to ZCL_EXCEL_STYLE .
ENDCLASS.



CLASS ZCL_TIMESHEET_MANAGEMENT IMPLEMENTATION.


  METHOD add_thin_border.
    DATA(lo_border) = NEW zcl_excel_style_border( ).
    lo_border->border_style     = zcl_excel_style_border=>c_border_thin.
    lo_border->border_color-rgb = '000000'.
    io_style->borders->allborders = lo_border.

  ENDMETHOD.


  METHOD sent_mail_for_time_off.



*--------------------------------------------------------------------*
* Send Leave Request Mail
*--------------------------------------------------------------------*


    DATA:
      lo_send_request TYPE REF TO cl_bcs,
      lo_document     TYPE REF TO cl_document_bcs,
      lo_recipient    TYPE REF TO if_recipient_bcs,
      lo_sender       TYPE REF TO if_sender_bcs,
      lt_mail_body    TYPE bcsy_text,
      lv_subject      TYPE so_obj_des,
      lv_html         TYPE string,
      lv_line         TYPE soli.

*--------------------------------------------------------------------*
* Prepare HTML Header
*--------------------------------------------------------------------*
    SELECT SINGLE FROM zrap_leave_type
      FIELDS code
      WHERE description = @is_leave-leave_type
      INTO @DATA(lv_code).

    SELECT FROM zrap_emp_gv
      FIELDS *
      INTO TABLE @DATA(lt_emp).
    SELECT FROM zi_appr_gv
      FIELDS *
      WHERE timeid = @is_leave-timeid AND
            empid = @is_leave-emp_id
      INTO TABLE @DATA(lt_apprv).

    SELECT SINGLE FROM zi_ts_hdr_gv
   FIELDS *
   WHERE timeid = @is_leave-timeid AND
         empid = @is_leave-emp_id
   INTO @DATA(ls_header).

    DATA(ls_send) = VALUE #( lt_emp[ emp_id = is_leave-emp_id ] OPTIONAL ).
    IF ls_send IS NOT INITIAL.
      DATA(ls_rec) = VALUE #( lt_emp[ emp_id = ls_send-manager_id ] OPTIONAL ).
    ENDIF.
    DATA: lv_query_part TYPE string,
          lv_fragment   TYPE string.
    DATA : ls_sender  TYPE zrap_emp_gv,
           ls_reciver TYPE zrap_emp_gv.


*   lv_query_part =
*    |https://tech.sapvista.com:44300/sap/bc/adt/businessservices/odatav4/feap| &&
*    |?feapParams=C%C2%87u%C2%84C%C2%83%C2%84%C2%89C%C2%83xu%C2%88uHC%C2%87u%C2%84| &&
*    |%C2%8E%C2%87vs%C2%88%C2%87s%C2%81u%C2%82u%7By%C2%81y%C2%82%C2%88C%C2%87%C2%86| &&
*    |%C2%8AxC%C2%87u%C2%84C%C2%8E%C2%87xs%C2%88%C2%87s%C2%81u%C2%82u%7By%C2%81y| &&
*    |%C2%82%C2%88CDDDEC77h%7D%C2%81y%C2%87%7Cyy%C2%88s%7Cyuxy%C2%8677su%C2%84| &&
*    |%C2%84%C2%86TTs%C2%80yu%C2%8Ay%7C%7D%C2%87%C2%88%C2%83%C2%86%C2%8DTTs| &&
*    |%C2%88%C2%87%7D%C2%88y%C2%8177nWsu%C2%84%C2%84%C2%86s%7B%C2%8ATT%60yu| &&
*    |%C2%8Ays%5C%7D%C2%87%C2%88%C2%83%C2%86%C2%8DTTh%7D%C2%81y%C2%87%7Cyy| &&
*    |%C2%88s%7D%C2%88y%C2%8177ngXshgsaUbU%5BYaYbh77DDDE77ngVshgsaUbU| &&
*    |%5BYaYbh&sap-ui-xx-viewCache=false&sap-ui-language=EN&sap-client=200|.
*
*  " IMPORTANT: this must match the ACTUAL entity set / key names
*  " exposed by the service ($metadata) - here that is
*  " Timesheet_header with key field TimeId, NOT "Leave_header"/
*  " "LeaveId". Using a name that doesn't exist in $metadata is
*  " why the preview app fails to load (it can't resolve the
*  " entity). "Leave Type" can still be shown as plain content in
*  " the mail body table - it just isn't the OData entity name.
*  lv_fragment =
*    |#/Timesheet_header(TimeId='{ ls_header-timeid }',EmpId='{ ls_header-empid }',IsActiveEntity=true)|.
*
*  " decision param sits in the query string (before #), fragment
*  " stays exactly as the router expects - untouched, at the end.
*  DATA(lv_approve_url) = lv_query_part && |&decision=APPROVE| && lv_fragment.
*  data(lv_reject_url)  = lv_query_part && |&decision=REJECT|  && lv_fragment.
    lv_subject =
      |{ ls_header-zmonth } { is_leave-leave_type } - { ls_send-emp_name }|.
    IF iv_status IS INITIAL .
      ls_sender = ls_send.
      ls_reciver = ls_rec.
    ELSE.
      ls_sender = ls_rec.
      ls_reciver = ls_send.
    ENDIF.

    lv_html =
      |<html><body style="margin:0;padding:0;background-color:#eef2f7;| &&
      |font-family:Arial,Helvetica,sans-serif;">| &&
      |<table width="100%" cellpadding="0" cellspacing="0">| &&
      |<tr><td align="center" style="padding:20px 0;">| &&
      |<table width="600" cellpadding="0" cellspacing="0" | &&
      |style="background-color:#ffffff;border-radius:4px;">| &&

      |<tr><td style="background-color:#1a4d7c;padding:18px 24px;">| &&
      |<span style="color:#ffffff;font-size:18px;font-weight:bold;">| &&
      |🗓️ Employee Request Management System</span></td></tr>| &&

      |<tr><td style="padding:24px;">| &&
      |<p style="font-size:14px;color:#333333;">Dear { ls_reciver-emp_name },</p>| &&
      COND #( WHEN iv_status IS INITIAL THEN |<p style="font-size:14px;color:#333333;">I have submitted a request for your review and approval.</p>|
              ELSE |<p style="font-size:14px;color:#333333;">Your leave request has been reviewed.</p>| ) &&
        |<p style="font-size:14px;color:#333333;">Please find the request details below:</p>| &&

      |<table width="100%" cellpadding="10" cellspacing="0" | &&
      |style="border:1px solid #dfe6ee;font-size:14px;color:#333333;">| &&
      |<tr style="background-color:#f5f8fb;">| &&
      |<td style="font-weight:bold;width:40%;">Employee ID</td>| &&
      |<td>{ ls_header-empid }</td></tr>| &&
      |<tr><td style="font-weight:bold;">Date</td>| &&
      |<td>{ is_leave-startdate+6(2) } { ls_header-zmonth } { is_leave-startdate+0(4) }</td></tr>| &&
      |<tr style="background-color:#f5f8fb;">| &&
      |<td style="font-weight:bold;">Leave Type</td>| &&
      |<td>{ is_leave-leave_type }</td></tr>| &&
      |<tr><td style="font-weight:bold;">Leave Duration</td>| &&
      |<td>{ is_leave-period }</td></tr>| &&
      |<tr style="background-color:#f5f8fb;">| &&
      |<td style="font-weight:bold;">Current Status</td>| &&
      |<td style="color:| &&  COND #( WHEN is_leave-status = 'Approved' THEN |#2e8540|
                                      WHEN is_leave-status = 'Rejected' THEN |#c9302c|
                                      ELSE |#f0ad4e| ) && |;font-weight:bold;">{ is_leave-status }</td></tr>| &&
      |</table>| &&

      |<p style="font-size:14px;color:#333333;margin:20px 0 16px 0;">| &&
      COND #( WHEN iv_status IS INITIAL THEN |Please review my leave request and take the necessary action at your convenience.</p>|
              ELSE |Your leave request has been { is_leave-status }.</p>| ) &&
      |<p style="font-size:14px;color:#333333;margin:20px 0 16px 0;">| &&
      |Thank you for your time and consideration.</p>| &&

*  |<table align="center" cellpadding="0" cellspacing="0">| &&
*  |<tr>| &&
*  |<td style="padding:0 8px;">| &&
*  |<a href="{ lv_approve_url }" target="_blank" | &&
*  |style="display:inline-block;background-color:#2e8540;| &&
*  |color:#ffffff;text-decoration:none;font-size:14px;| &&
*  |font-weight:bold;padding:12px 28px;border-radius:3px;">| &&
*  |✅ Approve</a></td>| &&
*
*  |<td style="padding:0 8px;">| &&
*  |<a href="{ lv_reject_url }" target="_blank" | &&
*  |style="display:inline-block;background-color:#c9302c;| &&
*  |color:#ffffff;text-decoration:none;font-size:14px;| &&
*  |font-weight:bold;padding:12px 28px;border-radius:3px;">| &&
*  |❌ Reject</a></td>| &&
*  |</tr></table>| &&

      |<p style="font-size:14px;color:#333333;margin-top:24px;">| &&
      |Regards,<br><strong>{ ls_sender-emp_name }</strong></p>| &&
      |</td></tr></table></td></tr></table></body></html>|.

    "-----------------------------------------------------------------
    " Safe conversion: splits at 255-char boundaries WITHOUT dropping
    " any characters (unlike manually typed VALUE #( line = |...| )
    " rows, which truncate if a single row exceeds 255 chars).
    "-----------------------------------------------------------------

    lt_mail_body = cl_document_bcs=>string_to_soli( ip_string = lv_html ).
*--------------------------------------------------------------------*
* Create and Send Email
*--------------------------------------------------------------------*

    TRY.

        lo_send_request = cl_bcs=>create_persistent( ).


*--------------------------------------------------------------------*
* Create HTML Document
*--------------------------------------------------------------------*

        lo_document = cl_document_bcs=>create_document(
          i_type    = 'HTM'
          i_text    = lt_mail_body
          i_subject = lv_subject ).

        lo_send_request->set_document(
          i_document = lo_document ).


*--------------------------------------------------------------------*
* Set Sender - Employee
*--------------------------------------------------------------------*

        lo_sender =
          cl_cam_address_bcs=>create_internet_address(
            i_address_string = CONV #( ls_sender-email ) ).

        lo_send_request->set_sender(
          i_sender = lo_sender ).


*--------------------------------------------------------------------*
* Add Recipient - Manager
*--------------------------------------------------------------------*

        lo_recipient =
          cl_cam_address_bcs=>create_internet_address(
            i_address_string = CONV #( ls_reciver-email ) ).

        lo_send_request->add_recipient(
          i_recipient = lo_recipient ).
        DATA : ls_cc_rec TYPE zrap_emp_gv.
        DATA : lo_cc_rec TYPE REF TO cl_cam_address_bcs.
        IF lt_apprv IS INITIAL.
          DATA(ls_man_cc) = VALUE #( lt_emp[ emp_id = ls_reciver-manager_id ] OPTIONAL ).
          IF ls_man_cc IS NOT INITIAL.
            lo_cc_rec = cl_cam_address_bcs=>create_internet_address(
                             i_address_string = CONV #( ls_man_cc-email ) ).
            lo_send_request->add_recipient(
                      i_recipient = lo_cc_rec
                      i_copy = abap_true ).
          ENDIF.
        ELSE.
          LOOP AT lt_apprv INTO DATA(ls_apprv) WHERE apprid NE 'F260000'.
            IF iv_status IS INITIAL.
              IF ls_apprv-apprid NE ls_reciver-emp_id.
                ls_cc_rec = VALUE #( lt_emp[ emp_id = ls_apprv-apprid ] OPTIONAL ).
                lo_cc_rec = cl_cam_address_bcs=>create_internet_address(
                             i_address_string = CONV #( ls_cc_rec-email ) ).
                lo_send_request->add_recipient(
                          i_recipient = lo_cc_rec
                          i_copy = abap_true ).
              ENDIF.
            ELSE.
              IF ls_apprv-apprid NE ls_sender-emp_id.
                ls_cc_rec = VALUE #( lt_emp[ emp_id = ls_apprv-apprid ] OPTIONAL ).
                lo_cc_rec  = cl_cam_address_bcs=>create_internet_address(
                            i_address_string = CONV #( ls_cc_rec-email ) ).
                lo_send_request->add_recipient(
                          i_recipient = lo_cc_rec
                          i_copy = abap_true ).
              ENDIF.
            ENDIF.
          ENDLOOP.
        ENDIF.
        DATA(ls_cc_hr) =  VALUE #( lt_apprv[ apprid = 'H260000' ] OPTIONAL ).
        IF ls_cc_hr IS INITIAL.
          lo_cc_rec = cl_cam_address_bcs=>create_internet_address(
                        i_address_string = CONV #( 'hr@vrikshamsofttech.com' ) ).
          lo_send_request->add_recipient(
                    i_recipient = lo_cc_rec
                    i_copy = abap_true ).
        ENDIF.
*--------------------------------------------------------------------*
* Send Email
*--------------------------------------------------------------------*

        DATA(lv_send) = lo_send_request->send(
                          i_with_error_screen = abap_true ).

        ev_send = lv_send.
      CATCH cx_bcs INTO DATA(lx_bcs).

    ENDTRY.


  ENDMETHOD.


METHOD get_timesheet.

  "-------------------------------------------------------------------
  " Rewritten to use ABAP2XLSX (ZCL_EXCEL) instead of CL_SALV_TABLE.
  "
  " WHY: CL_SALV_TABLE->TO_XML( ) only supports the 7 fixed ALV
  " palette colours (COL_BACKGROUND=1 .. COL_NEGATIVE=7 as used with
  " LVC_S_COLO). It cannot emit arbitrary RGB values, so it can never
  " reproduce hex colours such as C1E4F5, F1A983, 92D050, 00B0F0,
  " C00000, 7030A0, 0070C0, 0B769F, F6C6AC that the reference workbook
  " (Godson_C_-_VST_-_Aug_2026.xlsx) actually uses.
  "
  " Also note: in the reference file, colour is only ever applied to
  " the small legend key in column A (rows 8-18) - the attendance
  " codes in the day-grid itself (row 4) have NO fill at all. The old
  " logic coloured the day-grid cells instead, which is why it never
  " matched.
  "-------------------------------------------------------------------
  TYPES: BEGIN OF ty_count,
           code  TYPE char10,
           count TYPE i,
         END OF ty_count.
  TYPES: BEGIN OF ty_legend,
           code        TYPE char10,
           description TYPE char50,
           color       TYPE char6,
           count       TYPE i,
         END OF ty_legend.

  DATA: lo_excel          TYPE REF TO zcl_excel,
        lo_ws             TYPE REF TO zcl_excel_worksheet,
        lo_writer         TYPE REF TO zif_excel_writer,
        lv_xstring        TYPE xstring,
        lv_date           TYPE sy-datum,
        lv_col            TYPE i,
        lv_col_alpha      TYPE string,
        lv_last_col       TYPE i,
        lv_last_col_alpha TYPE string,
        lv_day            TYPE scal-indicator,
        lv_day_name       TYPE string,
        lv_code           TYPE char10,
        lv_emp_name       TYPE string,
        lv_project        TYPE string,
        lv_row            TYPE i,
        lt_legend         TYPE TABLE OF ty_legend,
        lt_counts         TYPE HASHED TABLE OF ty_count WITH UNIQUE KEY code.

  " ------------------------------------------------------------------
  " Style objects: created ONCE, reused for every cell (abap2xlsx best
  " practice - avoids one style object per cell, which bloats the file
  " and slows down write_file()).
  " ------------------------------------------------------------------
  DATA: lo_style_title   TYPE REF TO zcl_excel_style,
        lo_style_label   TYPE REF TO zcl_excel_style,
        lo_style_dayname TYPE REF TO zcl_excel_style,
        lo_style_datenum TYPE REF TO zcl_excel_style,
        lo_style_data    TYPE REF TO zcl_excel_style,
        lo_style_countbg TYPE REF TO zcl_excel_style,
        lo_style_total   TYPE REF TO zcl_excel_style,
        lo_style_code    TYPE REF TO zcl_excel_style.

  CREATE OBJECT lo_excel.
  lo_ws = lo_excel->get_active_worksheet( ).

  DATA(lt_months) = VALUE string_table(
    ( `Jan` ) ( `Feb` ) ( `Mar` ) ( `Apr` ) ( `May` ) ( `Jun` )
    ( `Jul` ) ( `Aug` ) ( `Sep` ) ( `Oct` ) ( `Nov` ) ( `Dec` ) ).
  lo_ws->set_title( |{ lt_months[ CONV i( iv_startdate+4(2) ) ] } { iv_startdate(4) }| ).

  lo_ws->set_column_width( ip_column = 'A' ip_width_fix = 12 ).
  lo_ws->set_column_width( ip_column = 'B' ip_width_fix = 30 ).

  lv_col = 2.
  lv_date = iv_startdate.
  WHILE lv_date <= iv_enddate.
    lv_col += 1.
    lo_ws->set_column_width( ip_column = zcl_excel_common=>convert_column2alpha( lv_col )
                              ip_width_fix = 6 ).
    lv_date = lv_date + 1.
  ENDWHILE.

  " ------------------------------------------------------------------
  " Styles - colours copied 1:1 from the reference workbook
  " ------------------------------------------------------------------
  lo_style_title = lo_excel->add_new_style( ).
  lo_style_title->font->bold = abap_true.
  lo_style_title->font->size = 36.
  lo_style_title->alignment->horizontal = zcl_excel_style_alignment=>c_horizontal_center.
  lo_style_title->number_format->format_code = 'mmm-yyyy'.

  lo_style_label = lo_excel->add_new_style( ).                       "A2:B4
  lo_style_label->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
  lo_style_label->fill->fgcolor-rgb = 'C1E4F5' .
  lo_style_label->font->bold = abap_true.
  add_thin_border( lo_style_label ).

  lo_style_dayname = lo_excel->add_new_style( ).                     "C2:AG2
  lo_style_dayname->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
  lo_style_dayname->fill->fgcolor-rgb ='F1A983'.
  lo_style_dayname->alignment->horizontal = zcl_excel_style_alignment=>c_horizontal_center.
  add_thin_border( lo_style_dayname ).

  lo_style_datenum = lo_excel->add_new_style( ).                     "C3:AG3
  lo_style_datenum->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
  lo_style_datenum->fill->fgcolor-rgb ='FAE2D5' .
  lo_style_datenum->alignment->horizontal = zcl_excel_style_alignment=>c_horizontal_center.
  add_thin_border( lo_style_datenum ).

  lo_style_data = lo_excel->add_new_style( ).                        "C4:AG4 - no fill
  lo_style_data->alignment->horizontal = zcl_excel_style_alignment=>c_horizontal_center.

  lo_style_countbg = lo_excel->add_new_style( ).                     "C8:C18
  lo_style_countbg->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
  lo_style_countbg->fill->fgcolor-rgb ='F2F2F2' .
  add_thin_border( lo_style_countbg ).

  lo_style_total = lo_excel->add_new_style( ).                       "B19/C19
  lo_style_total->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
  lo_style_total->fill->fgcolor-rgb ='F2F2F2' .
  lo_style_total->font->bold = abap_true.
  add_thin_border( lo_style_total ).

  " ------------------------------------------------------------------
  " Employee master data (rows 2-4, columns A-B)
  " ------------------------------------------------------------------
  SELECT SINGLE FROM zrap_emp_gv
    FIELDS emp_name
    WHERE emp_id = @iv_employee
    INTO @lv_emp_name.

  SELECT FROM zi_leave_history
    FIELDS *
    WHERE timeid = @( it_attendance[ 1 ]-time_id ) AND
          empid = @( it_attendance[ 1 ]-emp_id )
    INTO TABLE @DATA(lt_leave).
  SELECT FROM zrap_project_gv
    FIELDS pro_name
    WHERE emp_id = @iv_employee
    INTO TABLE @DATA(lt_project).
  DATA : lt_string TYPE truxs_t_text_data.
  CALL FUNCTION 'SAP_CONVERT_TO_TEX_FORMAT'
    EXPORTING
      i_field_seperator    = ','
*     I_LINE_HEADER        =
*     I_FILENAME           =
*     I_APPL_KEEP          = ' '
*     I_STEP               = 5
    TABLES
      i_tab_sap_data       = lt_project
    CHANGING
      i_tab_converted_data = lt_string
    EXCEPTIONS
      conversion_failed    = 1
      OTHERS               = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  lv_project =  VALUE #( lt_string[ 1 ] OPTIONAL ).

  lo_ws->set_cell( ip_column = 'A' ip_row = 2 ip_value = 'Name'    ip_style = lo_style_label ).
  lo_ws->set_cell( ip_column = 'B' ip_row = 2 ip_value = lv_emp_name ip_style = lo_style_label ).
  lo_ws->set_cell( ip_column = 'A' ip_row = 3 ip_value = 'EID'     ip_style = lo_style_label ).
  lo_ws->set_cell( ip_column = 'B' ip_row = 3 ip_value = iv_employee ip_style = lo_style_label ).
  lo_ws->set_cell( ip_column = 'A' ip_row = 4 ip_value = 'Project' ip_style = lo_style_label ).
  lo_ws->set_cell( ip_column = 'B' ip_row = 4 ip_value = lv_project ip_style = lo_style_label ).

  " ------------------------------------------------------------------
  " Day grid: day-name row (2), date-number row (3), attendance row (4)
  " starting at column C (index 3)
  " ------------------------------------------------------------------
  lv_date = iv_startdate.
  lv_col  = 2.

  lt_legend = VALUE #(
    ( code = 'P'    description = 'Present'                            color = '92D050' )
    ( code = 'EL'   description = 'Earned Leave'                       color = '00B0F0' )
    ( code = 'SCL'  description = 'Sick Leave / Casual Leave'          color = 'FFFF00' )
    ( code = 'UL'   description = 'Loss of Pay'                        color = 'C00000' )
    ( code = 'WFH'  description = 'Work From Home'                     color = '7030A0' )
    ( code = 'CH'   description = 'Client Holiday'                     color = '00B050' )
    ( code = 'WH'   description = 'Weekend Holiday'                    color = '0070C0' )
    ( code = 'WS'   description = 'Weekend Support'                    color = '0B769F' )
    ( code = 'HEL'  description = 'Half Day Earned Leave'              color = '00B0F0' )
    ( code = 'HDW'  description = 'Half Day Weekend Support'           color = 'F6C6AC' )
    ( code = 'HSCL' description = 'Half Day Sick Leave / Casual Leave' color = 'FFFF00' ) ).
  WHILE lv_date <= iv_enddate.
    lv_col      += 1.
    lv_col_alpha = zcl_excel_common=>convert_column2alpha( lv_col ).

    CALL FUNCTION 'DATE_COMPUTE_DAY'
      EXPORTING
        date = lv_date
      IMPORTING
        day  = lv_day.

    lv_day_name = SWITCH #( lv_day
                    WHEN 1 THEN 'Mon' WHEN 2 THEN 'Tue' WHEN 3 THEN 'Wed'
                    WHEN 4 THEN 'Thu' WHEN 5 THEN 'Fri' WHEN 6 THEN 'Sat'
                    WHEN 7 THEN 'Sun' ).

    lo_ws->set_cell( ip_column = lv_col_alpha ip_row = 2
                      ip_value = lv_day_name  ip_style = lo_style_dayname ).
    lo_ws->set_cell( ip_column = lv_col_alpha ip_row = 3
                      ip_value = lv_date+6(2) ip_style = lo_style_datenum ).

    " -- attendance code: WH for weekends, P where an attendance
    "    record exists for the date, blank otherwise. Extend this
    "    IF the source table (IT_ATTENDANCE) is enhanced to carry a
    "    status field for EL/SCL/UL/WFH/CH/WS/half-day codes.
    IF iv_button = 'X'.
      IF lv_day = 6 OR lv_day = 7.
        DATA(lv_ws) = xsdbool( line_exists( it_attendance[ zdate = lv_date status = 'Approved' ] ) ).
        lv_code = COND #( WHEN lv_ws = abap_true
                          THEN 'WS'
                          ELSE 'WH').

      ELSEIF line_exists( it_attendance[ zdate = lv_date status = 'Approved' ] ).
        lv_code = 'P'.
      ELSE.
        IF lv_date <= sy-datum.
          lv_code = 'UL'.
        ELSE.
          CLEAR lv_code.
        ENDIF.
      ENDIF.
    ELSE.
      IF lv_day = 6 OR lv_day = 7.
        DATA(lv_ws1) = xsdbool( line_exists( it_attendance[ zdate = lv_date ] ) ).
        lv_code = COND #( WHEN lv_ws1 = abap_true
                          THEN 'WS'
                          ELSE 'WH').
      ELSEIF line_exists( it_attendance[ zdate = lv_date ] ).
        lv_code = 'P'.
      ELSE.
        IF lv_date <= sy-datum.
          lv_code = 'UL'.
        ELSE.
          CLEAR lv_code.
        ENDIF.
      ENDIF.
    ENDIF.
    DATA : ls_leave TYPE zi_leave_history.
    IF iv_button = abap_true.
      ls_leave = VALUE #( lt_leave[ startdate = lv_date status = 'Approved' ] OPTIONAL ).
      IF ls_leave IS NOT INITIAL.
        lv_code = VALUE #( lt_legend[ description = ls_leave-leavetype ]-code OPTIONAL ).
        CLEAR ls_leave.
      ENDIF.
    ELSE.
      ls_leave = VALUE #( lt_leave[ startdate = lv_date  ] OPTIONAL ).
      IF ls_leave IS NOT INITIAL.
        lv_code = VALUE #( lt_legend[ description = ls_leave-leavetype ]-code OPTIONAL ).
        CLEAR ls_leave.
      ENDIF.
    ENDIF.
    DATA(lv_color) = VALUE #( lt_legend[ code = lv_code ]-color OPTIONAL ).

    lo_style_data = lo_excel->add_new_style( ).
    lo_style_data->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
    lo_style_data->fill->fgcolor-rgb = COND #( WHEN  lv_color IS INITIAL
                                               THEN 'F2F2F2' ELSE lv_color ).
    add_thin_border( lo_style_data ).
    CLEAR lv_color.
    lo_ws->set_cell( ip_column = lv_col_alpha ip_row = 4
                      ip_value = lv_code ip_style = lo_style_data ).
    IF lv_code IS NOT INITIAL.
      ASSIGN lt_counts[ code = lv_code ] TO FIELD-SYMBOL(<ls_count>).
      IF sy-subrc = 0.
        <ls_count>-count = <ls_count>-count + 1.
      ELSE.
        INSERT VALUE #( code = lv_code count = 1 ) INTO TABLE lt_counts.
      ENDIF.
    ENDIF.
    lv_date = lv_date + 1.
  ENDWHILE.

  lv_last_col       = lv_col.
  lv_last_col_alpha = zcl_excel_common=>convert_column2alpha( lv_last_col ).

  " ------------------------------------------------------------------
  " Row 1 - period title, merged A1:AD1
  " ------------------------------------------------------------------
  lo_ws->set_cell( ip_column = 'A' ip_row = 1 ip_value = iv_startdate ip_style = lo_style_title ).
  lo_ws->set_merge( ip_column_start = 'A' ip_row = 1
                     ip_column_end   = lv_last_col_alpha ip_row_to  = 1 ).

  " ------------------------------------------------------------------
  " Legend / summary block (rows 8-18): colour lives ONLY on the code
  " cell in column A, exactly like the reference. Counts are live
  " COUNTIF formulas over the day grid, same as the reference sheet.
  " ------------------------------------------------------------------

  lv_row = 7.
  DATA(lv_grand_total) = 0.
  LOOP AT lt_legend INTO DATA(ls_legend).
    lv_row += 1.

    " one style per distinct colour is enough - if you want to shave
    " this further, pre-create the 9 distinct colour styles above the
    " loop (P/EL/HEL share, SCL/HSCL share) instead of per-row.
    lo_style_code = lo_excel->add_new_style( ).
    lo_style_code->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
    lo_style_code->fill->fgcolor-rgb = ls_legend-color .
    add_thin_border( lo_style_code ).
    lo_ws->set_cell( ip_column = 'A' ip_row = lv_row
                      ip_value = ls_legend-code        ip_style = lo_style_code ).
    lo_style_code = lo_excel->add_new_style( ).
    lo_style_code->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
    lo_style_code->fill->fgcolor-rgb = 'F2F2F2'.
    add_thin_border( lo_style_code ).
    lo_ws->set_cell( ip_column = 'B' ip_row = lv_row
                      ip_value = ls_legend-description   ip_style = lo_style_code ).

    READ TABLE lt_counts WITH TABLE KEY code = ls_legend-code
                             ASSIGNING FIELD-SYMBOL(<ls_this_count>).
    DATA(lv_count) = COND i( WHEN sy-subrc = 0 THEN <ls_this_count>-count ELSE 0 ).
    lv_grand_total += lv_count.
    lo_ws->set_cell( ip_column = 'C' ip_row = lv_row
                          ip_value = lv_count ip_style = lo_style_countbg ).
  ENDLOOP.

  " ------------------------------------------------------------------
  " Total row
  " ------------------------------------------------------------------
  lv_row += 1.
  lo_ws->set_cell( ip_column = 'B' ip_row = lv_row ip_value = 'Total' ip_style = lo_style_total ).
  lo_ws->set_cell( ip_column = 'C' ip_row = lv_row ip_value = lv_grand_total ip_style = lo_style_total ).

  et_att = VALUE #( FOR ls_att IN lt_legend LET ls_count = VALUE #( lt_counts[ code = ls_att-code ] OPTIONAL ) IN
                        ( code = ls_att-code
                          description = ls_att-description
                          count = ls_count-count ) ).

  " ------------------------------------------------------------------
  " Serialize to XLSX
  " ------------------------------------------------------------------
  CREATE OBJECT lo_writer TYPE zcl_excel_writer_2007.
  lv_xstring  = lo_writer->write_file( lo_excel ).
  rv_attachement = lv_xstring.

ENDMETHOD.


  METHOD sent_mail_for_approval.


*---------------------------------------------------------------------*
* Data Declaration
*---------------------------------------------------------------------*
    DATA:
      lo_send_request TYPE REF TO cl_bcs,
      lo_document     TYPE REF TO cl_document_bcs,
      lo_recipient    TYPE REF TO if_recipient_bcs,
      lo_cc_recipient TYPE REF TO if_recipient_bcs,
      lt_body         TYPE bcsy_text.


    SELECT FROM zrap_appr_gv
      FIELDS *
      WHERE time_id = @iv_timeid AND
            emp_id = @iv_empid
      INTO TABLE @DATA(lt_aprv).
    SELECT  SINGLE FROM zi_ts_hdr_gv
      FIELDS *
      WHERE timeid = @iv_timeid AND
                empid = @iv_empid AND
                zmonth = @iv_month
      INTO @DATA(ls_header).

    SELECT FROM zrap_emp_gv
      FIELDS *
      INTO TABLE @DATA(lt_emp).


    DATA : lt_item TYPE TABLE OF zrap_ts_item.

    SELECT FROM zrap_ts_item
      FIELDS *
      WHERE time_id = @ls_header-timeid AND
            emp_id = @ls_header-empid
          INTO TABLE @lt_item.

    zcl_timesheet_management=>get_timesheet(
  EXPORTING
    iv_button      = abap_true
    iv_startdate   = ls_header-startdate               " Date
    iv_enddate     = ls_header-enddate              " Date
    it_attendance  = lt_item              " Table type for item
    iv_employee    = ls_header-empid             " Character Field with Length 10
  IMPORTING
    et_att         =  DATA(it_att)               " Present
  RECEIVING
    rv_attachement = DATA(lv_xstring)
).
    IF lv_xstring IS NOT INITIAL.
      UPDATE zrap_ts_hrd SET attchement = lv_xstring WHERE time_id = ls_header-timeid AND emp_id = ls_header-empid.
    ENDIF.
    DATA(lv_total_day) = REDUCE i( INIT x = 0
                               FOR wa IN it_att
                               NEXT x = x + wa-count ).
    DATA(ls_sender) = VALUE #( lt_emp[ email = iv_user ] OPTIONAL ).
    DATA(ls_reciver) = VALUE #( lt_emp[ emp_id = ls_sender-manager_id ] OPTIONAL ).

    DATA(lv_role_id) = VALUE #( lt_emp[ email = iv_user ] OPTIONAL ).

    SELECT SINGLE FROM zrap_role_gv
      FIELDS role
      WHERE role_id = @lv_role_id-role_id
      INTO @DATA(lv_role_name).



    TRY.

        "---------------------------------------------------------------
        " Mail Body - HTML
        "---------------------------------------------------------------
        lt_body = VALUE #( BASE lt_body

          ( line = '<html>' )
          ( line = '<body style="font-family:Arial;font-size:10pt;">' )

          ( line = |<p>Hi { ls_reciver-emp_name },</p>| )

          ( line = COND #( WHEN lv_role_name = 'Employee'
                           THEN |<p>Kindly review and approve my timesheet for { iv_month } { ls_header-startdate+0(4) }.</p>|
                          ELSE  |</p>Please find the approved timesheet for @{ ls_header-emp_name } for the month of { iv_month } { ls_header-startdate+0(4) }.</p>| ) )

          ( line = '<br>' )

          ( line = '<table border="1" cellpadding="5" cellspacing="0" ' &&
                    'style="border-collapse:collapse;">' ) ).
        LOOP AT it_att ASSIGNING FIELD-SYMBOL(<fs_att>).
          lt_body = VALUE #(  BASE lt_body ( line = |<tr><td align="center">{ <fs_att>-code }</td><td>{ <fs_att>-description }</td><td align="center">{ <fs_att>-count }</td></tr>| ) ).
        ENDLOOP.

        " Total
        lt_body = VALUE #(  BASE lt_body  ( line = |<tr style="font-weight:bold;background-color:#F2F2F2;"><td></td><td>Total</td><td align="center">{ lv_total_day }</td></tr>| )

          ( line = '</table>' )

          ( line = '<br>' )

          ( line = |<p>The detailed { COND #( WHEN lv_role_name NE 'Employee' THEN |approved| ) } timesheet is attached as an Excel file for your reference and further processing.</p>| )

          ( line = COND #( WHEN lv_role_name NE 'Employee'
                           THEN |<p>Kindly review the attached timesheet and proceed with the necessary action { COND #( WHEN lv_role_name = 'Manger' THEN |from the Finance team| ) }.</p>| ) )

          ( line = |<p>Thanks & Regards,<br>{ ls_sender-emp_name }</p>| )

          ( line = '</body>' )
          ( line = '</html>' )
        ).

        "---------------------------------------------------------------
        " Create Send Request
        "---------------------------------------------------------------
        lo_send_request = cl_bcs=>create_persistent( ).

        "---------------------------------------------------------------
        " Create HTML Document
        "---------------------------------------------------------------
        lo_document = cl_document_bcs=>create_document(
                        i_type    = 'HTM'
                        i_text    = lt_body
                        i_subject = CONV #( ls_header-filename ) ).

        DATA:
          lt_attachment TYPE solix_tab,
          lv_size       TYPE i.

        " Your Excel XSTRING


        " Convert XSTRING to binary
        CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
          EXPORTING
            buffer        = CONV xstring( lv_xstring )
          IMPORTING
            output_length = lv_size
          TABLES
            binary_tab    = lt_attachment.

        " Add Excel attachment
        lo_document->add_attachment(
          i_attachment_type    = 'EXT'
          i_attachment_subject = CONV #( ls_header-filename )
          i_attachment_size    = CONV sood-objlen( lv_size )
          i_att_content_hex    = lt_attachment
          i_attachment_header  = VALUE #(
            ( line = |&SO_FILENAME={ ls_header-filename }| )
          ) ).

        lo_send_request->set_document( lo_document ).
        DATA(lo_sender) = cl_cam_address_bcs=>create_internet_address(
                            CONV #( ls_sender-email ) ).

        lo_send_request->set_sender(
          i_sender = lo_sender ).
        "---------------------------------------------------------------
        " TO - Vengatakrishnan P
        "---------------------------------------------------------------
        lo_recipient =
          cl_cam_address_bcs=>create_internet_address(
            CONV #( ls_reciver-email ) ).

        lo_send_request->add_recipient(
          i_recipient = lo_recipient
          i_express   = abap_true ).

        "---------------------------------------------------------------
        " CC - Keerthana S
        "---------------------------------------------------------------
        LOOP AT lt_aprv INTO DATA(ls_apprv).
          IF ( ls_apprv-appr_id NE ls_reciver-emp_id ) AND ( ls_apprv-appr_id NE ls_sender-emp_id ) .
            DATA(lv_cc_reciver) = VALUE #( lt_emp[ emp_id = ls_apprv-appr_id ] OPTIONAL ).
            lo_cc_recipient =
              cl_cam_address_bcs=>create_internet_address(
                CONV #( lv_cc_reciver-email ) ).

            lo_send_request->add_recipient(
              i_recipient = lo_cc_recipient
              i_copy      = abap_true ).
          ENDIF.
        ENDLOOP.
        "---------------------------------------------------------------
        " CC - Vinodhini D
        "---------------------------------------------------------------
        DATA(ls_hr) = VALUE #( lt_aprv[ appr_id = 'H260000' ] OPTIONAL ).
        IF ls_hr IS INITIAL.
          lo_cc_recipient =
            cl_cam_address_bcs=>create_internet_address(
              'hr@virkshamsofttech.com' ).

          lo_send_request->add_recipient(
            i_recipient = lo_cc_recipient
            i_copy      = abap_true ).

        ENDIF.
        DATA(ls_send_cc) = VALUE #( lt_emp[ emp_id = iv_empid ] OPTIONAL ).
        IF ls_send_cc IS NOT INITIAL.
          IF iv_user NE ls_send_cc-email.
            lo_cc_recipient =
           cl_cam_address_bcs=>create_internet_address(
             CONV #( ls_send_cc-email ) ).

            lo_send_request->add_recipient(
              i_recipient = lo_cc_recipient
              i_copy      = abap_true ).
          ENDIF.
        ENDIF.

        "---------------------------------------------------------------
        " Send Mail
        "---------------------------------------------------------------
        DATA(lv_code) = lo_send_request->send( i_with_error_screen = abap_false ).

*        COMMIT WORK.
        ev_send = lv_code.
      CATCH cx_bcs INTO DATA(lx_bcs).

    ENDTRY.
  ENDMETHOD.


  METHOD get_memory_id.
    SELECT SINGLE FROM zrap_para_id
      FIELDS para_id
      WHERE uname = @sy-uname AND zdate = @sy-datum
      INTO @DATA(lv_user).
    IF sy-subrc IS INITIAL.
      rv_user = lv_user.
    ENDIF.
  ENDMETHOD.


  METHOD set_memory_id.
    DATA lv_user TYPE zrap_userid-userid.
    IF iv_user IS NOT INITIAL.
      DATA(ls_para) = VALUE zrap_para_id( uname   = sy-uname
                                          zdate   = sy-datum
                                          para_id = iv_user ).
      SELECT FROM zrap_para_id
        FIELDS * WHERE uname = @sy-uname
        INTO TABLE @DATA(lt_para_id).
      IF sy-subrc IS INITIAL.
        LOOP AT lt_para_id ASSIGNING FIELD-SYMBOL(<fs_para>).
          UPDATE zrap_userid SET status = 'Logout' WHERE userid = <fs_para>-uname.
        ENDLOOP.
      ENDIF.
      DELETE from zrap_para_id.
      MODIFY zrap_para_id FROM @ls_para.
      IF sy-subrc IS INITIAL.
        rv_set = abap_true.
      ENDIF.
    ELSE.

      DELETE FROM zrap_para_id WHERE uname = sy-uname.
      IF sy-subrc IS INITIAL.
        rv_set = abap_true.
      ENDIF.
    ENDIF.

  ENDMETHOD.


METHOD get_payslip.

*  DATA: lv_fm_name      TYPE funcname,
*        ls_outputparams TYPE sfpoutputparams,
*        ls_docparams    TYPE sfpdocparams,
*        ls_formoutput   TYPE fpformoutput.
*
*  "----------------------------------------------------------
*  " Open Adobe Form Job
*  "----------------------------------------------------------
*  ls_outputparams-nodialog = abap_true.
*  ls_outputparams-getpdf   = abap_true.
*
*  CALL FUNCTION 'FP_JOB_OPEN'
*    CHANGING
*      ie_outputparams = ls_outputparams
*    EXCEPTIONS
*      cancel          = 1
*      usage_error     = 2
*      system_error    = 3
*      internal_error  = 4
*      OTHERS          = 5.
*
*  IF sy-subrc <> 0.
*    RETURN.
*  ENDIF.
*
*  "----------------------------------------------------------
*  " Get generated Function Module
*  "----------------------------------------------------------
*  CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
*    EXPORTING
*      i_name     = 'ZG_TIME_SHEET'
*    IMPORTING
*      e_funcname = lv_fm_name.
*
*  "----------------------------------------------------------
*  " Call Adobe Form
*  "----------------------------------------------------------
*  CALL FUNCTION lv_fm_name
*    EXPORTING
*      /1bcdwb/docparams  = ls_docparams
*      is_header          = is_header
*      is_item            = is_item
*    IMPORTING
*      /1bcdwb/formoutput = ls_formoutput
*    EXCEPTIONS
*      usage_error        = 1
*      system_error       = 2
*      internal_error     = 3
*      OTHERS             = 4.
*
*  IF sy-subrc <> 0.
*    CALL FUNCTION 'FP_JOB_CLOSE'.
*    RETURN.
*  ENDIF.
*
*  "----------------------------------------------------------
*  " Close Adobe Form Job
*  "----------------------------------------------------------
*  CALL FUNCTION 'FP_JOB_CLOSE'
*    EXCEPTIONS
*      usage_error    = 1
*      system_error   = 2
*      internal_error = 3
*      OTHERS         = 4.
*
*  IF sy-subrc <> 0.
*    RETURN.
*  ENDIF.
*
*  "----------------------------------------------------------
*  " PDF XSTRING
*  "----------------------------------------------------------
*  rv_attachement = ls_formoutput-pdf.

  DATA: gv_fm_name TYPE rs38l_fnam,
        gs_ctrl    TYPE ssfctrlop,
        gs_opt     TYPE ssfcompop,
        gs_job     TYPE ssfcrescl,
        gt_lines   TYPE STANDARD TABLE OF tline,
        gv_pdf     TYPE xstring,
        gv_size    TYPE i,
        gt_bin     TYPE solix_tab.
  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname           = 'ZRAP_PAYSLIP_GV'
    IMPORTING
      fm_name            = gv_fm_name
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  gs_ctrl-no_dialog = abap_true.
  gs_ctrl-getotf    = abap_true.
  gs_ctrl-preview   = abap_false.
  gs_opt-tddest     = 'LP01'.       " any valid device, not really used with GETOTF
  gs_opt-tdnoprev   = abap_true.
  gs_opt-tdnoprint  = abap_true.

  CALL FUNCTION gv_fm_name "'/1BCDWB/SF00000241'
    EXPORTING
      control_parameters = gs_ctrl
      output_options     = gs_opt
      user_settings      = space
      is_header          = is_header
      is_item            = is_item
    IMPORTING
*     DOCUMENT_OUTPUT_INFO       =
      job_output_info    = gs_job
*     JOB_OUTPUT_OPTIONS =
    EXCEPTIONS
      formatting_error   = 1
      internal_error     = 2
      send_error         = 3
      user_canceled      = 4
      OTHERS             = 5.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.


  CALL FUNCTION 'CONVERT_OTF'
    EXPORTING
      format                = 'PDF'
    IMPORTING
      bin_filesize          = gv_size
      bin_file              = gv_pdf
    TABLES
      otf                   = gs_job-otfdata
      lines                 = gt_lines
    EXCEPTIONS
      err_max_linewidth     = 1
      err_format            = 2
      err_conv_not_possible = 3
      err_bad_otf           = 4
      OTHERS                = 5.
  IF sy-subrc <> 0.
    MESSAGE 'PDF conversion failed' TYPE 'E'.
  ENDIF.

  gt_bin = cl_bcs_convert=>xstring_to_solix( iv_xstring = gv_pdf ).
  rv_attachement = gv_pdf.

ENDMETHOD.
ENDCLASS.
