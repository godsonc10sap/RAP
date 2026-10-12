CLASS lhc_zi_expenses DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_expenses RESULT result.

    METHODS expenses_approve FOR MODIFY
      IMPORTING keys FOR ACTION zi_expenses~expenses_approve RESULT result.

    METHODS expenses_reject FOR MODIFY
      IMPORTING keys FOR ACTION zi_expenses~expenses_reject RESULT result.

ENDCLASS.

CLASS lhc_zi_expenses IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD expenses_approve.
    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
    ENTITY zi_expenses ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_expenses).
    IF lt_expenses IS INITIAL.
      RETURN.
    ENDIF.
    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
    ENTITY zi_expenses UPDATE FIELDS ( Status )
    WITH VALUE #( FOR ls_expense IN lt_expenses ( %tky = ls_expense-%tky
                                                  Status = 'Approved' ) ).
    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
 ENTITY zi_expenses ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_expenses1).

    result = VALUE #( FOR ls_exp IN lt_expenses1 ( %tky = ls_exp-%tky
                                                   %param = ls_exp ) ).

  ENDMETHOD.

  METHOD expenses_reject.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
    ENTITY zi_expenses ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_expenses).
    IF lt_expenses IS INITIAL.
      RETURN.
    ENDIF.
    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
    ENTITY zi_expenses UPDATE FIELDS ( Status )
    WITH VALUE #( FOR ls_expense IN lt_expenses ( %tky = ls_expense-%tky
                                                  Status = 'Rejected' ) ).
    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
 ENTITY zi_expenses ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_expenses1).

    result = VALUE #( FOR ls_exp IN lt_expenses1 ( %tky = ls_exp-%tky
                                                   %param = ls_exp ) ).
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
*&---------------------------------------------------------------------*
*& Local types of behavior pool ZBP_I_TS_HDR_GV
*& All messages come from message class ZTS_MSG (001 - 045)
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* Helper: month name
*----------------------------------------------------------------------*
CLASS lcl_util DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS get_month_name
      IMPORTING iv_date         TYPE d
      RETURNING VALUE(rv_month) TYPE char10.
ENDCLASS.

CLASS lcl_util IMPLEMENTATION.
  METHOD get_month_name.
    rv_month = SWITCH #( iv_date+4(2)
                         WHEN '01' THEN 'January'
                         WHEN '02' THEN 'February'
                         WHEN '03' THEN 'March'
                         WHEN '04' THEN 'April'
                         WHEN '05' THEN 'May'
                         WHEN '06' THEN 'June'
                         WHEN '07' THEN 'July'
                         WHEN '08' THEN 'August'
                         WHEN '09' THEN 'September'
                         WHEN '10' THEN 'October'
                         WHEN '11' THEN 'November'
                         WHEN '12' THEN 'December'
                         ELSE '' ).
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Leave history
*----------------------------------------------------------------------*
CLASS lhc_zi_leave_history DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    CONSTANTS c_msg TYPE symsgid VALUE 'ZG_TS_MSG'.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Zi_leave_history RESULT result.

    METHODS Approve_leave FOR MODIFY
      IMPORTING keys FOR ACTION Zi_leave_history~Approve_leave RESULT result.
    METHODS reject_leave FOR MODIFY
      IMPORTING keys FOR ACTION Zi_leave_history~reject_leave RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Zi_leave_history RESULT result.

ENDCLASS.

CLASS lhc_zi_leave_history IMPLEMENTATION.

  METHOD get_instance_features.

    " Approve / Reject leave is enabled only for the reporting manager of the employee.
    DATA(lv_user) = zcl_timesheet_management=>get_memory_id( ).
    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
               ENTITY zi_ts_hdr_gv
               ALL FIELDS WITH CORRESPONDING #( keys )
               RESULT DATA(lt_hdr).
    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_leave_history
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_leave).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
        ENTITY zi_ts_hdr_gv BY \_appr
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_appr).
    DATA(lv_appr) = lines( lt_appr ).
    SELECT FROM zrap_emp_gv
      FIELDS emp_id, manager_id, email
      INTO TABLE @DATA(lt_emp).

    LOOP AT lt_leave INTO DATA(ls_leave).

      DATA(ls_emp)    = VALUE #( lt_emp[ emp_id = ls_leave-EmpId ] OPTIONAL ).
      DATA(ls_mgr)    = VALUE #( lt_emp[ emp_id = ls_emp-manager_id ] OPTIONAL ).
      DATA(lv_is_mgr) = xsdbool( ls_mgr-email IS NOT INITIAL AND ls_mgr-email = lv_user ).
      DATA(lv_st_app) = xsdbool( line_exists( lt_hdr[ Status = 'Team Lead Approved' ] ) OR  line_exists( lt_hdr[ Status = 'HR Approved' ] )  ).

      APPEND VALUE #( %tky = ls_leave-%tky
                      %action-Approve_leave = COND #( WHEN lv_is_mgr = abap_true AND lv_appr <> 0 AND lv_st_app = abap_false
                                                       AND ( ls_leave-Status <> 'Approved' OR ls_leave-Status <> 'Rejected' )
                                                      THEN if_abap_behv=>fc-o-enabled
                                                      ELSE if_abap_behv=>fc-o-disabled )
                      %action-reject_leave  = COND #( WHEN lv_is_mgr = abap_true AND lv_appr <> 0 AND lv_st_app = abap_false
                                                       AND ls_leave-Status <> 'Rejected'
                                                      THEN if_abap_behv=>fc-o-enabled
                                                      ELSE if_abap_behv=>fc-o-disabled ) )
             TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD Approve_leave.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY Zi_leave_history
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_leave).

    IF lt_leave IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY Zi_leave_history
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR ls_leave IN lt_leave ( %tky   = ls_leave-%tky
                                               Status = 'Approved' ) ).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY Zi_leave_history
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_leave1).

    LOOP AT lt_leave1 INTO DATA(ls_leave1).

      DATA(ls_leave_his) = VALUE zrap_leave_his( emp_id     = ls_leave1-EmpId
                                                 leave_type = ls_leave1-LeaveType
                                                 period     = ls_leave1-Period
                                                 startdate  = ls_leave1-Startdate
                                                 status     = ls_leave1-Status
                                                 timeid     = ls_leave1-TimeId ).

      zcl_timesheet_management=>sent_mail_for_time_off(
        EXPORTING
          is_leave  = ls_leave_his
          iv_status = CONV char25( ls_leave_his-status )
        IMPORTING
          ev_send   = DATA(lv_send) ).

      IF lv_send = abap_true.
        " 037 Leave request for &1 approved. Employee notified by email.
        APPEND VALUE #( %tky = ls_leave1-%tky
                        %msg = new_message( id       = c_msg
                                            number   = '037'
                                            severity = if_abap_behv_message=>severity-success
                                            v1       = |{ ls_leave1-Startdate DATE = ENVIRONMENT }| ) )
               TO reported-zi_leave_history.
      ELSE.
        " 038 Leave request for &1 approved, but the email could not be sent.
        APPEND VALUE #( %tky = ls_leave1-%tky
                        %msg = new_message( id       = c_msg
                                            number   = '038'
                                            severity = if_abap_behv_message=>severity-warning
                                            v1       = |{ ls_leave1-Startdate DATE = ENVIRONMENT }| ) )
               TO reported-zi_leave_history.
      ENDIF.
    ENDLOOP.

    result = VALUE #( FOR ls_res IN lt_leave1 ( %tky   = ls_res-%tky
                                                %param = ls_res ) ).

  ENDMETHOD.

  METHOD reject_leave.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY Zi_leave_history
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_leave).

    IF lt_leave IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY Zi_leave_history
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR ls_leave IN lt_leave ( %tky   = ls_leave-%tky
                                               Status = 'Rejected' ) ).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY Zi_leave_history
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_leave1).

    SELECT FROM zrap_leave_bal
      FIELDS *
      FOR ALL ENTRIES IN @lt_leave1
      WHERE emp_id = @lt_leave1-EmpId
      INTO TABLE @DATA(lt_leave_bal).

    DATA(lt_leave_el)  = lt_leave_bal.
    DATA(lt_leave_scl) = lt_leave_bal.

    DELETE lt_leave_el  WHERE el >= 1.
    DELETE lt_leave_scl WHERE scl <> 0.

    LOOP AT lt_leave1 INTO DATA(ls_leave1).

      CASE ls_leave1-LeaveType.

        WHEN 'Earned Leave' OR 'Half Day Earned Leave'.
          ASSIGN lt_leave_el[ emp_id        = ls_leave1-EmpId
                              leave_date_el = ls_leave1-Startdate ] TO FIELD-SYMBOL(<fs_leave_el>).
          IF sy-subrc IS INITIAL.
            <fs_leave_el>-el = 1.
            UPDATE zrap_leave_bal SET el            = <fs_leave_el>-el
                                      leave_date_el = ''
                                WHERE emp_id        = ls_leave1-EmpId
                                  AND leave_date_el = <fs_leave_el>-leave_date_el.
          ENDIF.

        WHEN 'Half Day Sick Leave / Casual Leave' OR 'Sick Leave / Casual Leave'.
          LOOP AT lt_leave_scl ASSIGNING FIELD-SYMBOL(<fs_leave_scl>)
               WHERE leave_date_scl = ls_leave1-Startdate.
            <fs_leave_scl>-scl = '0.5'.
            UPDATE zrap_leave_bal SET scl            = <fs_leave_scl>-scl
                                      leave_date_scl = ''
                                WHERE emp_id         = ls_leave1-EmpId
                                  AND leave_date_scl = <fs_leave_scl>-leave_date_scl.
          ENDLOOP.

      ENDCASE.

      CLEAR lt_leave_bal.

      DATA(ls_leave_his) = VALUE zrap_leave_his( emp_id     = ls_leave1-EmpId
                                                 leave_type = ls_leave1-LeaveType
                                                 period     = ls_leave1-Period
                                                 startdate  = ls_leave1-Startdate
                                                 status     = ls_leave1-Status
                                                 timeid     = ls_leave1-TimeId ).

      zcl_timesheet_management=>sent_mail_for_time_off(
        EXPORTING
          is_leave  = ls_leave_his
          iv_status = CONV char25( ls_leave_his-status )
        IMPORTING
          ev_send   = DATA(lv_send) ).

      IF lv_send = abap_true.
        " 039 Leave request for &1 rejected. Employee notified by email.
        APPEND VALUE #( %tky = ls_leave1-%tky
                        %msg = new_message( id       = c_msg
                                            number   = '039'
                                            severity = if_abap_behv_message=>severity-success
                                            v1       = |{ ls_leave1-Startdate DATE = ENVIRONMENT }| ) )
               TO reported-zi_leave_history.
      ELSE.
        " 040 Leave request for &1 rejected, but the email could not be sent.
        APPEND VALUE #( %tky = ls_leave1-%tky
                        %msg = new_message( id       = c_msg
                                            number   = '040'
                                            severity = if_abap_behv_message=>severity-warning
                                            v1       = |{ ls_leave1-Startdate DATE = ENVIRONMENT }| ) )
               TO reported-zi_leave_history.
      ENDIF.
    ENDLOOP.

    result = VALUE #( FOR ls_res IN lt_leave1 ( %tky   = ls_res-%tky
                                                %param = ls_res ) ).

  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Saver
*----------------------------------------------------------------------*
CLASS lsc_zi_ts_hdr_gv DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zi_ts_hdr_gv IMPLEMENTATION.

  METHOD save_modified.

    DATA lt_item    TYPE TABLE OF zrap_ts_item.
    DATA lv_no_date TYPE d.
    DATA lv_xlsx    TYPE xstring.

    "------------------------------------------------------------------
    " 1. Timesheet deleted -> give the leave balance back
    "------------------------------------------------------------------
    IF delete-zi_ts_hdr_gv IS NOT INITIAL.

      LOOP AT delete-zi_leave_history ASSIGNING FIELD-SYMBOL(<fs_leave>).

        IF <fs_leave>-LeaveType = 'Earned Leave'
        OR <fs_leave>-LeaveType = 'Half Day Earned Leave'.

          UPDATE zrap_leave_bal
             SET el            = 1,
                 leave_date_el = @lv_no_date
           WHERE emp_id        = @<fs_leave>-EmpId
             AND leave_date_el = @<fs_leave>-Startdate.

        ELSEIF <fs_leave>-LeaveType = 'Half Day Sick Leave / Casual Leave'
            OR <fs_leave>-LeaveType = 'Sick Leave / Casual Leave'.

          UPDATE zrap_leave_bal
             SET scl            = '0.5',
                 leave_date_scl = @lv_no_date
           WHERE emp_id         = @<fs_leave>-EmpId
             AND leave_date_scl = @<fs_leave>-Startdate.

        ENDIF.
      ENDLOOP.
      LOOP AT delete-zi_ts_hdr_gv ASSIGNING FIELD-SYMBOL(<fs_hdr>).
        DELETE FROM zrap_attach_gv WHERE time_id = <fs_hdr>-TimeId AND emp_id = <fs_hdr>-EmpId.
      ENDLOOP.
    ENDIF.

*    "------------------------------------------------------------------
*    " 2. Collect the final list of daily entries
*    "------------------------------------------------------------------
*    IF create-zi_ts_item_gv IS NOT INITIAL.
*
*      SELECT FROM zrap_ts_item
*        FIELDS *
*        WHERE time_id = @( create-zi_ts_item_gv[ 1 ]-TimeId )
*          AND emp_id  = @( create-zi_ts_item_gv[ 1 ]-EmpId )
*        INTO TABLE @lt_item.
*
*      lt_item = VALUE #( BASE lt_item
*                         FOR ls_item IN create-zi_ts_item_gv
*                         ( checkin_time  = ls_item-Checkin_time
*                           checkout_time = ls_item-checkout_time
*                           emp_id        = ls_item-EmpId
*                           time_id       = ls_item-TimeId
*                           pro_id        = ls_item-ProId
*                           task          = ls_item-Task
*                           item_no       = ls_item-ItemNo
*                           zdate         = ls_item-Zdate
*                           zhours        = ls_item-Zhours ) ).
*    ENDIF.
*
*    IF update-zi_ts_item_gv IS NOT INITIAL.
*
*      SELECT FROM zrap_ts_item
*        FIELDS *
*        WHERE time_id = @( update-zi_ts_item_gv[ 1 ]-TimeId )
*          AND emp_id  = @( update-zi_ts_item_gv[ 1 ]-EmpId )
*        APPENDING TABLE @lt_item.
*
*      SORT lt_item BY time_id emp_id item_no.
*      DELETE ADJACENT DUPLICATES FROM lt_item COMPARING time_id emp_id item_no.
*
*      LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<ls_item>).
*
*        DATA(ls_update) = VALUE #( update-zi_ts_item_gv[ TimeId = <ls_item>-time_id
*                                                         EmpId  = <ls_item>-emp_id
*                                                         ItemNo = <ls_item>-item_no ] OPTIONAL ).
*        IF ls_update IS NOT INITIAL.
*          <ls_item>-zdate         = ls_update-zdate.
*          <ls_item>-pro_id        = ls_update-ProId.
*          <ls_item>-task          = ls_update-task.
*          <ls_item>-zhours        = ls_update-zhours.
*          <ls_item>-checkin_time  = ls_update-checkin_time.
*          <ls_item>-checkout_time = ls_update-checkout_time.
*        ENDIF.
*      ENDLOOP.
*    ENDIF.
*
*    IF delete-zi_ts_item_gv IS NOT INITIAL.
*
*      SELECT FROM zrap_ts_item
*        FIELDS *
*        WHERE time_id = @( delete-zi_ts_item_gv[ 1 ]-TimeId )
*          AND emp_id  = @( delete-zi_ts_item_gv[ 1 ]-EmpId )
*        APPENDING TABLE @lt_item.
*
*      LOOP AT delete-zi_ts_item_gv INTO DATA(ls_delete).
*        DELETE lt_item WHERE time_id = ls_delete-TimeId
*                         AND emp_id  = ls_delete-EmpId
*                         AND item_no = ls_delete-ItemNo.
*      ENDLOOP.
*    ENDIF.
*
*    "------------------------------------------------------------------
*    " 3. Build the Excel attachment from the daily entries
*    "------------------------------------------------------------------
*    IF lt_item IS NOT INITIAL.
*
*      DATA(lv_mon) = lcl_util=>get_month_name( sy-datum ).
*
*      TRY.
*          cl_salv_table=>factory(
*            IMPORTING
*              r_salv_table = DATA(lo_salv)
*            CHANGING
*              t_table      = lt_item ).
*
*          DATA(lo_columns) = lo_salv->get_columns( ).
*          lo_columns->get_column( 'TIME_ID' )->set_visible( abap_false ).
*          lo_columns->get_column( 'ITEM_NO' )->set_visible( abap_false ).
*          lo_columns->get_column( 'EMP_ID' )->set_long_text( 'Employee ID' ).
*          lo_columns->get_column( 'ZDATE' )->set_long_text( 'Date' ).
*          lo_columns->get_column( 'PRO_ID' )->set_long_text( 'Project ID' ).
*          lo_columns->get_column( 'TASK' )->set_long_text( 'Task Description' ).
*          lo_columns->get_column( 'ZHOURS' )->set_long_text( 'Hours' ).
*          lo_columns->get_column( 'CHECKIN_TIME' )->set_long_text( 'Check-in Time' ).
*          lo_columns->get_column( 'CHECKOUT_TIME' )->set_long_text( 'Check-out Time' ).
*          lo_columns->set_optimize( abap_true ).
*
*          lv_xlsx = lo_salv->to_xml( xml_type = if_salv_bs_xml=>c_type_xlsx ).
*
*        CATCH cx_root.
*          CLEAR lv_xlsx.   " Excel could not be built - keep the existing attachment untouched
*      ENDTRY.
*
*      IF lv_xlsx IS NOT INITIAL.
*
*        DATA(lv_filename) = |{ lv_mon } Timesheet.xlsx|.
*
*        UPDATE zrap_ts_hrd
*           SET attchement = @lv_xlsx,
*               filename   = @lv_filename,
*               mine_type  = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
*         WHERE time_id    = @( lt_item[ 1 ]-time_id )
*           AND emp_id     = @( lt_item[ 1 ]-emp_id ).
*      ENDIF.
*
*    ENDIF.

  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Header / Item handler
*----------------------------------------------------------------------*
CLASS lhc_zi_ts_hdr_gv DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS:
      c_msg            TYPE symsgid VALUE 'ZG_TS_MSG',
      c_finance_emp_id TYPE zrap_emp_gv-emp_id VALUE 'F260000',
      c_finance_mail   TYPE zrap_emp_gv-email  VALUE 'finance@vrikshamsofttech.com'.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_ts_hdr_gv RESULT result.
    METHODS get_week FOR DETERMINE ON SAVE
      IMPORTING keys FOR zi_ts_hdr_gv~get_week.
    METHODS dulipcate_employe FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_ts_hdr_gv~dulipcate_employe.
    METHODS daily_status FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_ts_hdr_gv~daily_status.
    METHODS update_status FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zi_ts_item_gv~update_status.
    METHODS validate_workedhours FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_ts_item_gv~validate_workedhours.
    METHODS update_status1 FOR DETERMINE ON SAVE
      IMPORTING keys FOR zi_ts_hdr_gv~update_status1.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zi_ts_item_gv RESULT result.
    METHODS approvetimesheet FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_hdr_gv~approvetimesheet RESULT result.
    METHODS earlynumbering_cba_tsitem FOR NUMBERING
      IMPORTING entities FOR CREATE zi_ts_hdr_gv\_tsitem.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE zi_ts_hdr_gv.
    METHODS login FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_hdr_gv~login.
    METHODS get_global_features FOR GLOBAL FEATURES
      IMPORTING REQUEST requested_features FOR zi_ts_hdr_gv RESULT result.
    METHODS rejecttimesheet FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_hdr_gv~rejecttimesheet RESULT result.
    METHODS logout FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_hdr_gv~logout.
    METHODS checkin FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_item_gv~checkin RESULT result.
    METHODS checkout FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_item_gv~checkout RESULT result.
    METHODS update_appr FOR DETERMINE ON SAVE
      IMPORTING keys FOR zi_ts_hdr_gv~update_appr.
    METHODS duplicate_entry FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_ts_item_gv~duplicate_entry.
    METHODS submitforapproval FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_hdr_gv~submitforapproval RESULT result.
    METHODS generatetimesheet FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_hdr_gv~generatetimesheet RESULT result.
    METHODS get_instance_features_1 FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zi_ts_hdr_gv RESULT result.
    METHODS applyleave FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_hdr_gv~applyleave RESULT result.
    METHODS approve FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_item_gv~approve RESULT result.
    METHODS reject FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_item_gv~reject RESULT result.
    METHODS resubmitforapproval FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_hdr_gv~resubmitforapproval RESULT result.
    METHODS approved FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_hdr_gv~approved RESULT result.
    METHODS expenses FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_hdr_gv~expenses RESULT result.
    METHODS rejected FOR MODIFY
      IMPORTING keys FOR ACTION zi_ts_hdr_gv~rejected RESULT result.
    METHODS get_instance_authorizations_1 FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_ts_item_gv RESULT result.
*    METHODS updatethroughexcel FOR DETERMINE ON MODIFY
*      IMPORTING keys FOR zi_ts_hdr_gv~updatethroughexcel.

ENDCLASS.

CLASS lhc_zi_ts_hdr_gv IMPLEMENTATION.

*======================================================================*
* AUTHORIZATION  (only authorization here - feature control is in
* GET_INSTANCE_FEATURES_1)
*======================================================================*
  METHOD get_instance_authorizations.

    " No instance restriction: every requested instance is allowed.
    result = VALUE #( FOR ls_key IN keys ( %tky = ls_key-%tky ) ).

  ENDMETHOD.

*======================================================================*
* EARLY NUMBERING
*======================================================================*
  METHOD earlynumbering_create.

    DATA : lv_num TYPE num10.

    DATA(lv_user) = zcl_timesheet_management=>get_memory_id( ).

    SELECT SINGLE FROM zrap_emp_gv
      FIELDS emp_id
      WHERE email = @lv_user
      INTO @DATA(lv_emp_id).

    IF sy-subrc <> 0 OR lv_emp_id IS INITIAL.
      LOOP AT entities INTO DATA(ls_err).
        APPEND VALUE #( %cid      = ls_err-%cid
                        %is_draft = ls_err-%is_draft ) TO failed-zi_ts_hdr_gv.
        " 008 Employee not found. Please log in again.
        APPEND VALUE #( %cid      = ls_err-%cid
                        %is_draft = ls_err-%is_draft
                        %msg      = new_message( id       = c_msg
                                                 number   = '008'
                                                 severity = if_abap_behv_message=>severity-error ) )
               TO reported-zi_ts_hdr_gv.
      ENDLOOP.
      RETURN.
    ENDIF.

    SELECT FROM zrap_ts_hrd
      FIELDS MAX( time_id )
      INTO @DATA(lv_active).

    SELECT FROM zts_hrddraft
      FIELDS MAX( timeid )
      INTO @DATA(lv_draft).

    lv_active = COND #( WHEN lv_active IS INITIAL
                        THEN '000000000'
                        ELSE lv_active ).

    lv_num = COND #( WHEN lv_active >= lv_draft
                     THEN lv_active
                     ELSE lv_draft ).

    LOOP AT entities INTO DATA(ls_entity).

      IF ls_entity-TimeId IS INITIAL.
        lv_num += 1.
      ENDIF.

      APPEND VALUE #( %cid      = ls_entity-%cid
                      %is_draft = ls_entity-%is_draft
                      EmpId     = lv_emp_id
                      TimeId    = COND #( WHEN ls_entity-TimeId IS NOT INITIAL
                                          THEN ls_entity-TimeId
                                          ELSE lv_num ) )
             TO mapped-zi_ts_hdr_gv.
    ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_cba_Tsitem.

    LOOP AT entities INTO DATA(ls_entity).

      SELECT FROM zrap_ts_item
        FIELDS MAX( item_no )
        WHERE time_id = @ls_entity-TimeId
          AND emp_id  = @ls_entity-EmpId
        INTO @DATA(lv_active).

      SELECT FROM zts_itemdraft
        FIELDS MAX( itemno )
        WHERE timeid = @ls_entity-TimeId
          AND empid  = @ls_entity-EmpId
        INTO @DATA(lv_draft).

      DATA(lv_num) = COND #( WHEN lv_active >= lv_draft
                             THEN lv_active
                             ELSE lv_draft ).

      LOOP AT ls_entity-%target INTO DATA(ls_item).

        IF ls_item-ItemNo IS INITIAL.
          lv_num += 1.      " every new item gets its own number
        ENDIF.

        APPEND VALUE #( %cid      = ls_item-%cid
                        %is_draft = ls_entity-%is_draft
                        TimeId    = ls_entity-TimeId
                        EmpId     = ls_entity-EmpId
                        ItemNo    = COND #( WHEN ls_item-ItemNo IS NOT INITIAL
                                            THEN ls_item-ItemNo
                                            ELSE lv_num ) )
               TO mapped-zi_ts_item_gv.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

*======================================================================*
* DETERMINATIONS
*======================================================================*
  METHOD get_week.

    DATA : lv_mon_beg TYPE sy-datum,
           lv_mon_end TYPE sy-datum.

    CALL FUNCTION 'HR_JP_MONTH_BEGIN_END_DATE'
      EXPORTING
        iv_date             = sy-datum
      IMPORTING
        ev_month_begin_date = lv_mon_beg
        ev_month_end_date   = lv_mon_end.

    DATA(lv_mon) = lcl_util=>get_month_name( sy-datum ).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hrd).

    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      UPDATE FIELDS ( Zmonth StartDate EndDate )
      WITH VALUE #( FOR ls_hrd IN lt_hrd ( %tky      = ls_hrd-%tky
                                           Zmonth    = lv_mon
                                           StartDate = lv_mon_beg
                                           EndDate   = lv_mon_end ) ).

  ENDMETHOD.

  METHOD update_status.

    " Item changed -> recalculate the total hours of its timesheet
    DATA lv_total_hours TYPE zrap_ts_item-zhours.
    DATA lt_update      TYPE TABLE FOR UPDATE zi_ts_hdr_gv.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_item_gv BY \_tsheader
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hrd).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv BY \_tsitem
      ALL FIELDS WITH CORRESPONDING #( lt_hrd )
      RESULT DATA(lt_item).

    LOOP AT lt_hrd INTO DATA(ls_hrd).

      CLEAR lv_total_hours.
      LOOP AT lt_item INTO DATA(ls_item)
           WHERE TimeId = ls_hrd-TimeId
             AND EmpId  = ls_hrd-EmpId.
        lv_total_hours += ls_item-Zhours.
      ENDLOOP.

      APPEND VALUE #( %tky       = ls_hrd-%tky
                      TotalHours = lv_total_hours ) TO lt_update.
    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
        ENTITY zi_ts_hdr_gv
        UPDATE FIELDS ( TotalHours )
        WITH lt_update.
    ENDIF.

  ENDMETHOD.

  METHOD update_status1.

    " On save: total hours + initial status 'Created'
    DATA lv_total_hours TYPE zrap_ts_item-zhours.
    DATA lt_update      TYPE TABLE FOR UPDATE zi_ts_hdr_gv.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hrd).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv BY \_tsitem
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    LOOP AT lt_hrd INTO DATA(ls_hrd).

      CLEAR lv_total_hours.
      LOOP AT lt_item INTO DATA(ls_item)
           WHERE TimeId = ls_hrd-TimeId
             AND EmpId  = ls_hrd-EmpId.
        lv_total_hours += ls_item-Zhours.
      ENDLOOP.

      APPEND VALUE #( %tky       = ls_hrd-%tky
                      TotalHours = lv_total_hours
                      Status     = COND #( WHEN ls_hrd-Status IS INITIAL
                                           THEN 'Created'
                                           ELSE ls_hrd-Status ) ) TO lt_update.
    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
        ENTITY zi_ts_hdr_gv
        UPDATE FIELDS ( TotalHours Status )
        WITH lt_update.
    ENDIF.

  ENDMETHOD.

  METHOD update_appr.
    " Approver determination is currently done in action SUBMITFORAPPROVAL.
  ENDMETHOD.

*======================================================================*
* VALIDATIONS
*======================================================================*
  METHOD dulipcate_employe.

    DATA(lv_mon) = lcl_util=>get_month_name( sy-datum ).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hrd).

    LOOP AT lt_hrd INTO DATA(ls_hrd).

      SELECT SINGLE FROM zi_ts_hdr_gv
        FIELDS EmpId
        WHERE EmpId  = @ls_hrd-EmpId
          AND Zmonth = @lv_mon
          AND TimeId <> @ls_hrd-TimeId
        INTO @DATA(lv_emp).

      IF sy-subrc = 0.
        APPEND VALUE #( %tky = ls_hrd-%tky ) TO failed-zi_ts_hdr_gv.
        " 009 Timesheet for &1 already exists for employee &2.
        APPEND VALUE #( %tky = ls_hrd-%tky
                        %element-EmpId = if_abap_behv=>mk-on
                        %msg = new_message( id       = c_msg
                                            number   = '009'
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = lv_mon
                                            v2       = ls_hrd-EmpId ) )
               TO reported-zi_ts_hdr_gv.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD daily_status.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv BY \_tsitem
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr).

    LOOP AT lt_hdr INTO DATA(ls_hdr).

      IF NOT line_exists( lt_item[ TimeId = ls_hdr-TimeId EmpId = ls_hdr-EmpId ] )
         AND ls_hdr-Attchement IS INITIAL.

        APPEND VALUE #( %tky = ls_hdr-%tky ) TO failed-zi_ts_hdr_gv.
        " 010 Add at least one daily entry or generate the file before saving.
        APPEND VALUE #( %tky = ls_hdr-%tky
                        %element-_tsitem = if_abap_behv=>mk-on
                        %msg = new_message( id       = c_msg
                                            number   = '010'
                                            severity = if_abap_behv_message=>severity-error ) )
               TO reported-zi_ts_hdr_gv.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validate_workedhours.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_item_gv
      FIELDS ( Zhours Zdate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    LOOP AT lt_item INTO DATA(ls_item) WHERE Zhours > 9.

      APPEND VALUE #( %tky = ls_item-%tky ) TO failed-zi_ts_item_gv.
      " 011 Worked hours on &1 exceed the daily limit of 9 hours.
      APPEND VALUE #( %tky = ls_item-%tky
                      %element-Zhours = if_abap_behv=>mk-on
                      %msg = new_message( id       = c_msg
                                          number   = '011'
                                          severity = if_abap_behv_message=>severity-error
                                          v1       = |{ ls_item-Zdate DATE = ENVIRONMENT }| ) )
             TO reported-zi_ts_item_gv.
    ENDLOOP.

  ENDMETHOD.

  METHOD duplicate_entry.

    DATA lt_dates TYPE SORTED TABLE OF sy-datum WITH UNIQUE KEY table_line.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_item_gv BY \_tsheader
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr).

    SORT lt_hdr BY TimeId EmpId.
    DELETE ADJACENT DUPLICATES FROM lt_hdr COMPARING TimeId EmpId.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv BY \_tsitem
      ALL FIELDS WITH CORRESPONDING #( lt_hdr )
      RESULT DATA(lt_item).

    LOOP AT lt_hdr INTO DATA(ls_hdr).

      CLEAR lt_dates.

      LOOP AT lt_item INTO DATA(ls_item)
           WHERE TimeId = ls_hdr-TimeId
             AND EmpId  = ls_hdr-EmpId.

        IF ls_item-Zdate IS INITIAL.
          CONTINUE.
        ENDIF.

        " same date entered twice
        INSERT ls_item-Zdate INTO TABLE lt_dates.
        IF sy-subrc <> 0.
          APPEND VALUE #( %tky = ls_item-%tky ) TO failed-zi_ts_item_gv.
          " 012 An entry already exists for &1. One entry per day is allowed.
          APPEND VALUE #( %tky = ls_item-%tky
                          %element-Zdate = if_abap_behv=>mk-on
                          %msg = new_message( id       = c_msg
                                              number   = '012'
                                              severity = if_abap_behv_message=>severity-error
                                              v1       = |{ ls_item-Zdate DATE = ENVIRONMENT }| ) )
                 TO reported-zi_ts_item_gv.

          " date outside the timesheet month
        ELSEIF ls_item-Zdate+4(2) <> ls_hdr-StartDate+4(2).
          APPEND VALUE #( %tky = ls_item-%tky ) TO failed-zi_ts_item_gv.
          " 013 &1 is outside the current timesheet month.
          APPEND VALUE #( %tky = ls_item-%tky
                          %element-Zdate = if_abap_behv=>mk-on
                          %msg = new_message( id       = c_msg
                                              number   = '013'
                                              severity = if_abap_behv_message=>severity-error
                                              v1       = |{ ls_item-Zdate DATE = ENVIRONMENT }| ) )
                 TO reported-zi_ts_item_gv.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

*======================================================================*
* FEATURE CONTROL
*======================================================================*
  METHOD get_global_features.

    DATA(lv_userid) = zcl_timesheet_management=>get_memory_id( ).

    SELECT SINGLE FROM zrap_userid
      FIELDS *
      WHERE userid = @lv_userid
        AND zdate  = @sy-datum
      INTO @DATA(ls_emp).

    SELECT SINGLE FROM zrap_emp_gv
      FIELDS role_id
      WHERE email = @lv_userid
      INTO @DATA(lv_role_id).

    SELECT SINGLE FROM zrap_role_gv
      FIELDS role
      WHERE role_id = @lv_role_id
      INTO @DATA(lv_role_name).

    " Create is allowed only for a logged-in user who is not HR
    IF ls_emp-status <> 'Login' OR lv_role_name = 'HR'.
      result-%create = if_abap_behv=>fc-o-disabled.
    ELSE.
      result-%create = if_abap_behv=>fc-o-enabled.
    ENDIF.

  ENDMETHOD.

  METHOD get_instance_features.

    " ITEM entity: update / delete + item actions
    DATA(lv_user) = zcl_timesheet_management=>get_memory_id( ).
    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
            ENTITY zi_ts_hdr_gv
            ALL FIELDS WITH CORRESPONDING #( keys )
            RESULT DATA(lt_hdr).
    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_item_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).
    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
         ENTITY zi_ts_hdr_gv BY \_appr
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(lt_appr).
    DATA(lv_apprv) = lines( lt_appr ).
    SELECT FROM zrap_emp_gv
      FIELDS emp_id, manager_id, email
      INTO TABLE @DATA(lt_emp).

    LOOP AT lt_item INTO DATA(ls_item).

      DATA(ls_emp)    = VALUE #( lt_emp[ emp_id = ls_item-EmpId ] OPTIONAL ).
      DATA(ls_mgr)    = VALUE #( lt_emp[ emp_id = ls_emp-manager_id ] OPTIONAL ).
      DATA(lv_is_mgr) = xsdbool( ls_mgr-email IS NOT INITIAL AND ls_mgr-email = lv_user ).
      DATA(lv_is_own) = xsdbool( ls_emp-email IS NOT INITIAL AND ls_emp-email = lv_user ).
      DATA(lv_st_app) = xsdbool( line_exists( lt_hdr[ Status = 'Team Lead Approved' ] ) OR  line_exists( lt_hdr[ Status = 'HR Approved' ] )  ).

      APPEND VALUE #(
        %tky    = ls_item-%tky

        %update = COND #( WHEN ls_item-Zdate IS INITIAL
                          THEN if_abap_behv=>fc-o-enabled
                          WHEN ls_item-Zdate < sy-datum
                          THEN if_abap_behv=>fc-o-disabled
                          ELSE if_abap_behv=>fc-o-enabled )

        %delete = COND #( WHEN ls_item-Zdate IS INITIAL
                          THEN if_abap_behv=>fc-o-enabled
                          WHEN ls_item-Zdate < sy-datum
                          THEN if_abap_behv=>fc-o-disabled
                          ELSE if_abap_behv=>fc-o-enabled )

        %action-approve  = COND #( WHEN lv_is_mgr = abap_true AND ls_item-Status <> 'Approved' AND lv_apprv <> 0 AND lv_st_app = abap_false
                                   THEN if_abap_behv=>fc-o-enabled
                                   ELSE if_abap_behv=>fc-o-disabled )
        %action-reject   = COND #( WHEN lv_is_mgr = abap_true AND ls_item-Status <> 'Rejected' AND lv_apprv <> 0 AND lv_st_app = abap_false
                                   THEN if_abap_behv=>fc-o-enabled
                                   ELSE if_abap_behv=>fc-o-disabled )
        %action-checkin  = COND #( WHEN lv_is_own = abap_true AND ls_item-Checkin_time IS INITIAL
                                   THEN if_abap_behv=>fc-o-enabled
                                   ELSE if_abap_behv=>fc-o-disabled )
        %action-checkout = COND #( WHEN lv_is_own = abap_true AND ls_item-checkout_time IS INITIAL
                                   THEN if_abap_behv=>fc-o-enabled
                                   ELSE if_abap_behv=>fc-o-disabled ) )
        TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_features_1.

    " HEADER entity: update + all header action buttons
    DATA ls_res  LIKE LINE OF result.
    DATA lt_appr TYPE TABLE FOR READ RESULT zi_ts_hdr_gv\_appr.
    DATA lt_item TYPE TABLE FOR READ RESULT zi_ts_hdr_gv\_tsitem.

    DATA(lv_user) = zcl_timesheet_management=>get_memory_id( ).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hrd).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv BY \_appr
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_appr_all).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv BY \_tsitem
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item_all).

    SELECT FROM zrap_emp_gv
      FIELDS emp_id, role_id, email
      INTO TABLE @DATA(lt_emp).

    SELECT FROM zrap_role_gv
      FIELDS *
      INTO TABLE @DATA(lt_role).

    DATA(ls_log_user) = VALUE #( lt_emp[ email = lv_user ] OPTIONAL ).
    IF lv_user IS INITIAL.
      CLEAR ls_log_user.
    ENDIF.
    DATA(ls_log_role) = VALUE #( lt_role[ role_id = ls_log_user-role_id ] OPTIONAL ).

    LOOP AT lt_hrd INTO DATA(ls_hrd).

      CLEAR ls_res.
      ls_res-%tky = ls_hrd-%tky.

      " ---- update (existing logic)
      ls_res-%update = COND #( WHEN ls_hrd-Status = 'Send for Approval'
                                 OR ls_hrd-Status = 'Team Lead Approved'
                                 OR ls_hrd-Status = 'Manager Approved'
                                 OR ls_hrd-Status = 'Finance Approved'
                               THEN if_abap_behv=>fc-o-disabled
                               ELSE if_abap_behv=>fc-o-enabled ).

      IF ls_hrd-%is_draft = if_abap_behv=>mk-on.

        " ---- record not created yet -> all buttons greyed out
        ls_res-%action-ApproveTimesheet    = if_abap_behv=>fc-o-disabled.
        ls_res-%action-rejecttimesheet     = if_abap_behv=>fc-o-disabled.
        ls_res-%action-generatetimesheet   = if_abap_behv=>fc-o-disabled.
        ls_res-%action-applyleave          = if_abap_behv=>fc-o-disabled.
        ls_res-%action-submitforapproval   = if_abap_behv=>fc-o-disabled.
        ls_res-%action-resubmitforapproval = if_abap_behv=>fc-o-disabled.
        ls_res-%action-approved            = if_abap_behv=>fc-o-disabled.
        ls_res-%action-rejected            = if_abap_behv=>fc-o-disabled.
        ls_res-%action-expenses            = if_abap_behv=>fc-o-disabled.

      ELSE.

        " ---- data of THIS timesheet only
        lt_appr = VALUE #( FOR ls_a IN lt_appr_all
                           WHERE ( TimeId = ls_hrd-TimeId AND EmpId = ls_hrd-EmpId )
                           ( ls_a ) ).
        lt_item = VALUE #( FOR ls_i IN lt_item_all
                           WHERE ( TimeId = ls_hrd-TimeId AND EmpId = ls_hrd-EmpId )
                           ( ls_i ) ).

        DATA(lv_count)     = lines( lt_appr ).
        DATA(lv_any_appr)  = xsdbool( line_exists( lt_appr[ Status = 'Approved' ] ) ).
        DATA(lv_item_appr) = xsdbool( line_exists( lt_item[ Status = 'Approved' ] ) ).
        DATA(lv_item_rej)  = xsdbool( line_exists( lt_item[ Status = 'Rejected' ] ) ).
        DATA(ls_my_appr)   = VALUE #( lt_appr[ ApprId = ls_log_user-emp_id ] OPTIONAL ).
        DATA(ls_f_appr)    = VALUE #( lt_appr[ ApprId = c_finance_emp_id ] OPTIONAL ).

        ls_res-%action-ApproveTimesheet = COND #(
          WHEN ls_log_role-role = 'Team Lead'
            THEN COND #( WHEN ls_hrd-Status <> 'Team Lead Approved' AND ls_my_appr-Status <> 'Approved' AND lv_item_appr = abap_true
                         THEN if_abap_behv=>fc-o-enabled
                         ELSE if_abap_behv=>fc-o-disabled )
          WHEN ls_log_role-role = 'HR'
            THEN COND #( WHEN ls_hrd-Status <> 'HR Approved' AND ls_my_appr-Status <> 'Approved' AND lv_item_appr = abap_true
                         THEN if_abap_behv=>fc-o-enabled
                         ELSE if_abap_behv=>fc-o-disabled )
          WHEN ls_log_role-role = 'Manager'
            THEN COND #( WHEN ls_hrd-Status <> 'Manager Approved' AND ls_my_appr-Status <> 'Approved'
                              AND lv_item_appr = abap_true
                         THEN if_abap_behv=>fc-o-enabled
                         ELSE if_abap_behv=>fc-o-disabled )
          ELSE if_abap_behv=>fc-o-disabled ).

        ls_res-%action-rejecttimesheet = COND #(
          WHEN ( ls_log_role-role = 'Team Lead' OR ls_log_role-role = 'HR' )
            THEN COND #( WHEN ls_hrd-Status <> 'Rejected' AND ls_f_appr-Status <> 'Approved' AND lv_item_rej = abap_true
                         THEN if_abap_behv=>fc-o-enabled
                         ELSE if_abap_behv=>fc-o-disabled )
          WHEN ls_log_role-role = 'Manager'
            THEN COND #( WHEN ls_hrd-Status <> 'Rejected' AND ls_f_appr-Status <> 'Approved'
                              AND lv_item_appr = abap_true
                         THEN if_abap_behv=>fc-o-enabled
                         ELSE if_abap_behv=>fc-o-disabled )
          ELSE if_abap_behv=>fc-o-disabled ).

        ls_res-%action-generatetimesheet = COND #(
          WHEN lv_count = 0 AND lv_any_appr = abap_false
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled ).

        ls_res-%action-applyleave = COND #(
          WHEN lv_count = 0 AND lv_any_appr = abap_false
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled ).

        ls_res-%action-submitforapproval = COND #(
          WHEN lv_count = 0 AND ls_hrd-Attchement IS NOT INITIAL
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled ).

        ls_res-%action-resubmitforapproval = COND #(
          WHEN lv_count <> 0 AND lv_any_appr = abap_false
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled ).

        ls_res-%action-approved = COND #(
          WHEN lv_user = c_finance_mail AND ls_hrd-Status <> 'Approved'
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled ).

        ls_res-%action-rejected = COND #(
          WHEN lv_user = c_finance_mail AND ls_hrd-Status <> 'Rejected'
          THEN if_abap_behv=>fc-o-enabled
          ELSE if_abap_behv=>fc-o-disabled ).

        ls_res-%action-expenses = if_abap_behv=>fc-o-enabled.   " add your own condition here if needed

      ENDIF.

      APPEND ls_res TO result.
    ENDLOOP.

  ENDMETHOD.

*======================================================================*
* USER ACTIONS : LOGIN / LOGOUT
*======================================================================*
  METHOD login.

    DATA(lv_password) = keys[ 1 ]-%param-Password.
    DATA(lv_userid)   = keys[ 1 ]-%param-userid.

    DATA(lv_user) = zcl_timesheet_management=>get_memory_id( ).
    IF lv_user IS NOT INITIAL.
      UPDATE zrap_userid SET status = 'Logout' WHERE userid = @lv_user.
    ENDIF.

    SELECT SINGLE FROM zrap_userid
      FIELDS *
      WHERE userid   = @lv_userid
        AND password = @lv_password
      INTO @DATA(ls_emp).

    IF ls_emp-emp_id IS NOT INITIAL.
      SELECT SINGLE FROM zrap_emp_gv
        FIELDS emp_name
        WHERE emp_id = @ls_emp-emp_id
        INTO @DATA(lv_emp_name).
    ENDIF.

    IF ls_emp-emp_id IS INITIAL.

      " 002 Invalid user ID or password. Please try again.
      APPEND VALUE #( %cid          = keys[ 1 ]-%cid
                      %create       = if_abap_behv=>mk-on
                      %action-login = if_abap_behv=>mk-on
                      %msg          = new_message( id       = c_msg
                                                   number   = '002'
                                                   severity = if_abap_behv_message=>severity-error ) )
             TO reported-zi_ts_hdr_gv.
      APPEND VALUE #( %cid = keys[ 1 ]-%cid ) TO failed-zi_ts_hdr_gv.

    ELSEIF ls_emp-zdate = sy-datum AND ls_emp-status = 'Login'.

      " 003 You are already logged in today.
      APPEND VALUE #( %cid    = keys[ 1 ]-%cid
                      %create = if_abap_behv=>mk-on
                      %msg    = new_message( id       = c_msg
                                             number   = '003'
                                             severity = if_abap_behv_message=>severity-information ) )
             TO reported-zi_ts_hdr_gv.

    ELSE.

      UPDATE zrap_userid
         SET status = 'Login',
             zdate  = @sy-datum
       WHERE userid   = @lv_userid
         AND password = @lv_password.

      IF sy-subrc IS INITIAL.

        DATA(lv_set) = zcl_timesheet_management=>set_memory_id( iv_user = lv_userid ).

        IF lv_set = abap_true.
          " 001 Login successful. Welcome, &1.
          APPEND VALUE #( %cid = keys[ 1 ]-%cid
                          %msg = new_message( id       = c_msg
                                              number   = '001'
                                              severity = if_abap_behv_message=>severity-success
                                              v1       = lv_emp_name ) )
                 TO reported-zi_ts_hdr_gv.
        ELSE.
          " 004 Login failed. Please try again.
          APPEND VALUE #( %cid          = keys[ 1 ]-%cid
                          %create       = if_abap_behv=>mk-on
                          %action-login = if_abap_behv=>mk-on
                          %msg          = new_message( id       = c_msg
                                                       number   = '004'
                                                       severity = if_abap_behv_message=>severity-error ) )
                 TO reported-zi_ts_hdr_gv.
          APPEND VALUE #( %cid = keys[ 1 ]-%cid ) TO failed-zi_ts_hdr_gv.
        ENDIF.

      ELSE.
        " 005 Login failed. User status could not be updated.
        APPEND VALUE #( %cid          = keys[ 1 ]-%cid
                        %create       = if_abap_behv=>mk-on
                        %action-login = if_abap_behv=>mk-on
                        %msg          = new_message( id       = c_msg
                                                     number   = '005'
                                                     severity = if_abap_behv_message=>severity-error ) )
               TO reported-zi_ts_hdr_gv.
        APPEND VALUE #( %cid = keys[ 1 ]-%cid ) TO failed-zi_ts_hdr_gv.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD logout.

    DATA(lv_user) = zcl_timesheet_management=>get_memory_id( ).

    SELECT SINGLE FROM zrap_userid
      FIELDS *
      WHERE userid = @lv_user
        AND zdate  = @sy-datum
      INTO @DATA(ls_emp).

    IF ls_emp-status <> 'Login'.

      " 007 You are not logged in.
      APPEND VALUE #( %cid    = keys[ 1 ]-%cid
                      %create = if_abap_behv=>mk-on
                      %msg    = new_message( id       = c_msg
                                             number   = '007'
                                             severity = if_abap_behv_message=>severity-information ) )
             TO reported-zi_ts_hdr_gv.

    ELSE.

      UPDATE zrap_userid
         SET status = 'Logout'
       WHERE emp_id = @ls_emp-emp_id
         AND userid = @ls_emp-userid
         AND zdate  = @ls_emp-zdate.

      CLEAR lv_user.
      DATA(lv_set) = zcl_timesheet_management=>set_memory_id( iv_user = lv_user ).

      " 006 You have been logged out successfully.
      APPEND VALUE #( %cid = keys[ 1 ]-%cid
                      %msg = new_message( id       = c_msg
                                          number   = '006'
                                          severity = if_abap_behv_message=>severity-success ) )
             TO reported-zi_ts_hdr_gv.
    ENDIF.

  ENDMETHOD.

*======================================================================*
* TIMESHEET ACTIONS
*======================================================================*
  METHOD ApproveTimesheet.

    DATA : lv_status  TYPE char25,
           lv_app_com TYPE char255,
           lv_msgno   TYPE symsgno.

    DATA(lv_user) = zcl_timesheet_management=>get_memory_id( ).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hrd).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv BY \_tsitem
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    IF lt_hrd IS INITIAL.
      RETURN.
    ENDIF.

    " ---- who is approving?
    SELECT SINGLE FROM zrap_emp_gv
      FIELDS emp_id, role_id
      WHERE email = @lv_user
      INTO @DATA(ls_emp).

    IF sy-subrc IS INITIAL.

      SELECT SINGLE FROM zrap_role_gv
        FIELDS role
        WHERE role_id = @ls_emp-role_id
        INTO @DATA(lv_role_name).

      IF sy-subrc IS INITIAL.
        CASE lv_role_name.
          WHEN 'Team Lead'.
            lv_status  = |Team Lead Approved|.
            lv_app_com = 'Timesheet approved and successfully routed to Manager for approval.'.
            lv_msgno   = '017'.   " Approved and forwarded to the Manager.
          WHEN 'Manager'.
            lv_status  = |Manager Approved|.
            lv_app_com = 'Timesheet approved and successfully routed to Finance for final approval.'.
            lv_msgno   = '018'.   " Approved and forwarded to Finance for final approval.
          WHEN 'HR'.
            lv_status  = |HR Approved|.
            lv_app_com = 'Timesheet approved and successfully routed to Finance for final approval.'.
            lv_msgno   = '018'.
        ENDCASE.
      ENDIF.
    ENDIF.

    IF lv_status IS INITIAL.
      " 014 You are not authorized to approve this timesheet.
      APPEND VALUE #( %tky = lt_hrd[ 1 ]-%tky ) TO failed-zi_ts_hdr_gv.
      APPEND VALUE #( %tky = lt_hrd[ 1 ]-%tky
                      %msg = new_message( id       = c_msg
                                          number   = '014'
                                          severity = if_abap_behv_message=>severity-error ) )
             TO reported-zi_ts_hdr_gv.
      RETURN.
    ENDIF.

    " ---- daily entries must be approved first
    IF NOT line_exists( lt_item[ Status = 'Approved' ] ).
      " 015 Approve the daily entries before approving the timesheet.
      APPEND VALUE #( %tky = lt_hrd[ 1 ]-%tky ) TO failed-zi_ts_hdr_gv.
      APPEND VALUE #( %tky = lt_hrd[ 1 ]-%tky
                      %element-%assoc-_tsitem = if_abap_behv=>mk-on
                      %msg = new_message( id       = c_msg
                                          number   = '015'
                                          severity = if_abap_behv_message=>severity-error ) )
             TO reported-zi_ts_hdr_gv.
      RETURN.
    ENDIF.

    " ---- mail to the next approver
    zcl_timesheet_management=>sent_mail_for_approval(
      EXPORTING
        iv_user   = CONV char50( lv_user )
        iv_timeid = lt_hrd[ 1 ]-TimeId
        iv_empid  = lt_hrd[ 1 ]-EmpId
        iv_month  = lt_hrd[ 1 ]-Zmonth
      IMPORTING
        ev_send   = DATA(lv_send) ).

    IF lv_send <> abap_true.
      " 016 Approval email could not be sent. Status was not changed.
      APPEND VALUE #( %tky = lt_hrd[ 1 ]-%tky ) TO failed-zi_ts_hdr_gv.
      APPEND VALUE #( %tky = lt_hrd[ 1 ]-%tky
                      %msg = new_message( id       = c_msg
                                          number   = '016'
                                          severity = if_abap_behv_message=>severity-error ) )
             TO reported-zi_ts_hdr_gv.
      RETURN.
    ENDIF.

    " ---- header status
    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR ls_key IN keys ( %tky   = ls_key-%tky
                                         Status = lv_status ) )
      REPORTED DATA(lt_repot).

    " ---- approver line
    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv BY \_appr
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_appr).

    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_appr_gv
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR ls_app IN lt_appr ( %tky   = ls_app-%tky
                                            Status = COND #( WHEN ls_app-ApprId = ls_emp-emp_id
                                                             THEN 'Approved'
                                                             ELSE ls_app-Status ) ) )
      REPORTED DATA(lt_repot1).

    DATA(lv_date) = cl_abap_context_info=>get_system_date( ).
    DATA(lv_time) = cl_abap_context_info=>get_system_time( ).

    UPDATE zrap_appr_gv
       SET a_comm  = @lv_app_com,
           d_apprv = @lv_date,
           t_apprv = @lv_time
     WHERE time_id = @( lt_hrd[ 1 ]-TimeId )
       AND emp_id  = @( lt_hrd[ 1 ]-EmpId )
       AND appr_id = @ls_emp-emp_id.

    " 017 / 018 approved and forwarded
    APPEND VALUE #( %tky = keys[ 1 ]-%tky
                    %msg = new_message( id       = c_msg
                                        number   = lv_msgno
                                        severity = if_abap_behv_message=>severity-success ) )
           TO reported-zi_ts_hdr_gv.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hrd1).

    result = VALUE #( FOR ls_hrd IN lt_hrd1 ( %tky   = ls_hrd-%tky
                                              %param = ls_hrd ) ).

  ENDMETHOD.

  METHOD rejecttimesheet.

*    " 019 Enter a reason before rejecting the timesheet.
*    IF condense( keys[ 1 ]-%param-remarks ) IS INITIAL.
*      APPEND VALUE #( %tky = keys[ 1 ]-%tky ) TO failed-zi_ts_hdr_gv.
*      APPEND VALUE #( %tky = keys[ 1 ]-%tky
*                      %msg = new_message( id       = c_msg
*                                          number   = '019'
*                                          severity = if_abap_behv_message=>severity-error ) )
*             TO reported-zi_ts_hdr_gv.
*      RETURN.
*    ENDIF.

    DATA(lv_user) = zcl_timesheet_management=>get_memory_id( ).

    SELECT SINGLE FROM zrap_emp_gv
      FIELDS emp_id
      WHERE email = @lv_user
      INTO @DATA(lv_emp).

    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR ls_key IN keys ( %tky   = ls_key-%tky
                                         Status = 'Rejected' ) )
      REPORTED DATA(lt_repot).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hrd).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv BY \_appr
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_appr).

    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_appr_gv
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR ls_app IN lt_appr ( %tky   = ls_app-%tky
                                            Status = COND #( WHEN ls_app-ApprId = lv_emp
                                                             THEN 'Rejected'
                                                             ELSE ls_app-Status ) ) )
      REPORTED DATA(lt_repot1).

    result = VALUE #( FOR ls_hrd IN lt_hrd ( %tky   = ls_hrd-%tky
                                             %param = ls_hrd ) ).

  ENDMETHOD.

  METHOD submitforapproval.

    DATA : lt_appr        TYPE TABLE OF zrap_appr_gv,
           lt_emp         TYPE STANDARD TABLE OF zrap_emp_gv  WITH DEFAULT KEY,
           lt_role        TYPE STANDARD TABLE OF zrap_role_gv WITH DEFAULT KEY,
           ls_emp         TYPE zrap_emp_gv,
           ls_emp2        TYPE zrap_emp_gv,
           ls_manager     TYPE zrap_emp_gv,
           ls_team_leader TYPE zrap_emp_gv,
           ls_finance     TYPE zrap_emp_gv,
           lv_role_name   TYPE zrap_role_gv-role,
           lv_mgr_role    TYPE zrap_role_gv-role,
           lv_app         TYPE i.

    DATA(lv_user) = zcl_timesheet_management=>get_memory_id( ).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hrd).

    IF lt_hrd IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM zrap_emp_gv
      FIELDS *
      INTO CORRESPONDING FIELDS OF TABLE @lt_emp.
    SELECT FROM zrap_role_gv
      FIELDS *
      INTO CORRESPONDING FIELDS OF TABLE @lt_role.

    IF sy-subrc IS INITIAL.

      ls_emp = VALUE #( lt_emp[ emp_id = lt_hrd[ 1 ]-EmpId ] OPTIONAL ).
      IF ls_emp IS NOT INITIAL.

        ls_emp2 = VALUE #( lt_emp[ emp_id = ls_emp-manager_id ] OPTIONAL ).
        IF ls_emp2 IS NOT INITIAL.

          lv_role_name = VALUE #( lt_role[ role_id = ls_emp2-role_id ]-role OPTIONAL ).
          IF lv_role_name = 'Team Lead'.
            ls_team_leader = ls_emp2.
            ls_manager     = VALUE #( lt_emp[ emp_id = ls_emp2-manager_id ] OPTIONAL ).
          ENDIF.

          IF ls_manager IS INITIAL.
            ls_manager = ls_emp2.
          ENDIF.

          ls_finance = VALUE #( lt_emp[ emp_id = c_finance_emp_id ] OPTIONAL ).
          IF ls_finance IS INITIAL.
            ls_finance = ls_manager.
            CLEAR ls_manager.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    LOOP AT lt_hrd ASSIGNING FIELD-SYMBOL(<fs_hrd>).

      " only a timesheet in status 'Created' can be submitted
      IF <fs_hrd>-Status <> 'Created'.
        " 021 Only a Created timesheet can be submitted. Current status: &1
        APPEND VALUE #( %tky = <fs_hrd>-%tky ) TO failed-zi_ts_hdr_gv.
        APPEND VALUE #( %tky = <fs_hrd>-%tky
                        %msg = new_message( id       = c_msg
                                            number   = '021'
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = <fs_hrd>-Status ) )
               TO reported-zi_ts_hdr_gv.
        CONTINUE.
      ENDIF.

      lv_app = 0.

      IF lv_role_name = 'Team Lead'.
        lv_app += 1.
        APPEND VALUE #( time_id  = <fs_hrd>-TimeId
                        emp_id   = <fs_hrd>-EmpId
                        appr_num = lv_app
                        zdate    = sy-datum
                        appr_id  = ls_team_leader-emp_id
                        approver = ls_team_leader-emp_name
                        status   = 'Pending Team Lead Approval' ) TO lt_appr.
      ENDIF.

      IF ls_manager IS NOT INITIAL.
        lv_app += 1.
        lv_mgr_role = VALUE #( lt_role[ role_id = ls_manager-role_id ]-role OPTIONAL ).
        APPEND VALUE #( time_id  = <fs_hrd>-TimeId
                        emp_id   = <fs_hrd>-EmpId
                        appr_num = lv_app
                        zdate    = sy-datum
                        appr_id  = ls_manager-emp_id
                        approver = ls_manager-emp_name
                        status   = COND #( WHEN lv_mgr_role = 'HR' OR ls_manager-emp_name = 'HR'
                                           THEN 'Pending HR Approval'
                                           ELSE 'Pending Manager Approval' ) ) TO lt_appr.
      ENDIF.

      IF ls_finance IS NOT INITIAL.
        lv_app += 1.
        APPEND VALUE #( time_id  = <fs_hrd>-TimeId
                        emp_id   = <fs_hrd>-EmpId
                        appr_num = lv_app
                        zdate    = sy-datum
                        appr_id  = ls_finance-emp_id
                        approver = ls_finance-emp_name
                        status   = 'Pending Finance Approval' ) TO lt_appr.
      ENDIF.
    ENDLOOP.

    IF lt_appr IS INITIAL.
      IF failed-zi_ts_hdr_gv IS INITIAL.
        " 022 No approver found for this employee. Please contact HR.
        APPEND VALUE #( %tky = lt_hrd[ 1 ]-%tky ) TO failed-zi_ts_hdr_gv.
        APPEND VALUE #( %tky = lt_hrd[ 1 ]-%tky
                        %msg = new_message( id       = c_msg
                                            number   = '022'
                                            severity = if_abap_behv_message=>severity-error ) )
               TO reported-zi_ts_hdr_gv.
      ENDIF.
      RETURN.
    ENDIF.

    MODIFY zrap_appr_gv FROM TABLE @lt_appr.
    IF sy-subrc IS INITIAL.

      zcl_timesheet_management=>sent_mail_for_approval(
        EXPORTING
          iv_user   = CONV char50( lv_user )
          iv_timeid = lt_hrd[ 1 ]-TimeId
          iv_empid  = lt_hrd[ 1 ]-EmpId
          iv_month  = lt_hrd[ 1 ]-Zmonth
        IMPORTING
          ev_send   = DATA(lv_send) ).

      IF lv_send = abap_true.

        MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
          ENTITY zi_ts_hdr_gv
          UPDATE FIELDS ( Status )
          WITH VALUE #( FOR ls_hdr1 IN lt_hrd ( %tky   = ls_hdr1-%tky
                                                Status = 'Send for Approval' ) ).

        " 025 Timesheet submitted for approval.
        APPEND VALUE #( %tky = keys[ 1 ]-%tky
                        %msg = new_message( id       = c_msg
                                            number   = '025'
                                            severity = if_abap_behv_message=>severity-success ) )
               TO reported-zi_ts_hdr_gv.
      ELSE.
        " 023 Approval email could not be sent. Timesheet not submitted.
        APPEND VALUE #( %tky = keys[ 1 ]-%tky ) TO failed-zi_ts_hdr_gv.
        APPEND VALUE #( %tky = keys[ 1 ]-%tky
                        %msg = new_message( id       = c_msg
                                            number   = '023'
                                            severity = if_abap_behv_message=>severity-error ) )
               TO reported-zi_ts_hdr_gv.
      ENDIF.

    ELSE.
      " 024 Approval request could not be saved. Please try again.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky ) TO failed-zi_ts_hdr_gv.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky
                      %msg = new_message( id       = c_msg
                                          number   = '024'
                                          severity = if_abap_behv_message=>severity-error ) )
             TO reported-zi_ts_hdr_gv.
    ENDIF.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hrd1).

    result = VALUE #( FOR ls_hdr IN lt_hrd1 ( %tky   = ls_hdr-%tky
                                              %param = ls_hdr ) ).

  ENDMETHOD.

  METHOD generatetimesheet.

    DATA lt_attendance TYPE TABLE OF zrap_ts_item.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv BY \_tsitem
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    LOOP AT lt_hdr ASSIGNING FIELD-SYMBOL(<fs_hdr>).

      SELECT SINGLE FROM zrap_emp_gv
        FIELDS emp_name
        WHERE emp_id = @<fs_hdr>-EmpId
        INTO @DATA(lv_emp_name).

      " daily entries of THIS timesheet only
      lt_attendance = VALUE #( FOR ls_item IN lt_item
                               WHERE ( TimeId = <fs_hdr>-TimeId AND EmpId = <fs_hdr>-EmpId )
                               ( time_id       = ls_item-TimeId
                                 emp_id        = ls_item-EmpId
                                 checkin_time  = ls_item-Checkin_time
                                 checkout_time = ls_item-checkout_time
                                 item_no       = ls_item-ItemNo
                                 pro_id        = ls_item-ProId
                                 task          = ls_item-Task
                                 zdate         = ls_item-Zdate
                                 zhours        = ls_item-Zhours
                                 status        = ls_item-Status ) ).

      <fs_hdr>-Attchement = zcl_timesheet_management=>get_timesheet(
                              iv_startdate  = <fs_hdr>-StartDate
                              iv_enddate    = <fs_hdr>-EndDate
                              it_attendance = lt_attendance
                              iv_employee   = <fs_hdr>-EmpId ).

      <fs_hdr>-Filename = |{ lv_emp_name } - VST - { <fs_hdr>-Zmonth+0(3) }'{ <fs_hdr>-StartDate+0(4) }.xlsx|.
      <fs_hdr>-MineType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.

      IF lt_attendance IS INITIAL.
        " 027 No daily entries found for &1. The timesheet file is empty.
        APPEND VALUE #( %tky = <fs_hdr>-%tky
                        %msg = new_message( id       = c_msg
                                            number   = '027'
                                            severity = if_abap_behv_message=>severity-warning
                                            v1       = <fs_hdr>-Zmonth ) )
               TO reported-zi_ts_hdr_gv.
      ELSE.
        " 028 Timesheet file &1 generated successfully.
        APPEND VALUE #( %tky = <fs_hdr>-%tky
                        %msg = new_message( id       = c_msg
                                            number   = '028'
                                            severity = if_abap_behv_message=>severity-success
                                            v1       = <fs_hdr>-Filename ) )
               TO reported-zi_ts_hdr_gv.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      UPDATE FIELDS ( Attchement Filename MineType )
      WITH VALUE #( FOR ls_hdr1 IN lt_hdr ( %tky       = ls_hdr1-%tky
                                            Attchement = ls_hdr1-Attchement
                                            Filename   = ls_hdr1-Filename
                                            MineType   = ls_hdr1-MineType ) ).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr1).

    result = VALUE #( FOR ls_hrd IN lt_hdr1 ( %tky   = ls_hrd-%tky
                                              %param = ls_hrd ) ).

  ENDMETHOD.

  METHOD applyleave.

    DATA : ls_leave_his  TYPE zrap_leave_his,
           lv_no_balance TYPE abap_bool,
           lv_month      TYPE n LENGTH 2,
           rt_month      TYPE RANGE OF num2.

    FIELD-SYMBOLS <fs_bal> TYPE zrap_leave_bal.

    DATA(ls_param)      = keys[ 1 ]-%param.
    DATA(lv_from_month) = ls_param-from_date+4(2).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr).

    IF lt_hdr IS INITIAL.
      RETURN.
    ENDIF.

    " ---- leave date must fall inside the timesheet period
    IF ls_param-from_date < lt_hdr[ 1 ]-StartDate OR ls_param-from_date > lt_hdr[ 1 ]-EndDate.

      " 033 Leave date &1 is outside the timesheet period.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky ) TO failed-zi_ts_hdr_gv.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky
                      %action-applyleave = if_abap_behv=>mk-on
                      %msg = new_message( id       = c_msg
                                          number   = '033'
                                          severity = if_abap_behv_message=>severity-error
                                          v1       = |{ ls_param-from_date DATE = ENVIRONMENT }| ) )
             TO reported-zi_ts_hdr_gv.
      RETURN.
    ENDIF.

    SELECT SINGLE FROM zi_leave_bal
      FIELDS *
      WHERE EmpId = @( keys[ 1 ]-EmpId )
      INTO @DATA(ls_leave_tot).

    SELECT FROM zrap_leave_bal
      FIELDS *
      WHERE emp_id = @( keys[ 1 ]-EmpId )
        AND zmonth <= @lv_from_month
      INTO TABLE @DATA(lt_leave_cnt).

    DATA(lt_leave_temp) = lt_leave_cnt.

    " ---- deduct the balance (in memory - saved only after the mail is sent)
    CASE ls_param-timeoff_type.

      WHEN 'Earned Leave'.
        IF ls_leave_tot-total_El GT 0.
          DELETE lt_leave_temp WHERE el < 1.
          lv_month = lines( lt_leave_temp ).
          LOOP AT lt_leave_cnt ASSIGNING <fs_bal> WHERE zmonth = lv_month.
            <fs_bal>-el = 0.
            <fs_bal>-leave_date_el = ls_param-from_date.
          ENDLOOP.
        ELSE.
          lv_no_balance = abap_true.
        ENDIF.

      WHEN 'Half Day Earned Leave'.
        IF ls_leave_tot-total_El GT 0.
          DELETE lt_leave_temp WHERE el = 0.
          lv_month = lines( lt_leave_temp ).
          LOOP AT lt_leave_cnt ASSIGNING <fs_bal> WHERE zmonth = lv_month.
            <fs_bal>-el = ( <fs_bal>-el - '0.5' ).
            <fs_bal>-leave_date_el = ls_param-from_date.
          ENDLOOP.
        ELSE.
          lv_no_balance = abap_true.
        ENDIF.

      WHEN 'Sick Leave / Casual Leave'.
        IF ls_leave_tot-total_Scl GE 1.
          DELETE lt_leave_temp WHERE scl = 0.
          lv_month = lines( lt_leave_temp ).
          rt_month = VALUE #( ( sign = 'I' option = 'EQ' low = lv_month )
                              ( sign = 'I' option = 'EQ' low = ( lv_month - 1 ) ) ).
          LOOP AT lt_leave_cnt ASSIGNING <fs_bal> WHERE zmonth IN rt_month.
            <fs_bal>-scl = 0.
            <fs_bal>-leave_date_scl = ls_param-from_date.
          ENDLOOP.
        ELSE.
          lv_no_balance = abap_true.
        ENDIF.

      WHEN 'Half Day Sick Leave / Casual Leave'.
        IF ls_leave_tot-total_Scl GT 0.
          DELETE lt_leave_temp WHERE scl = 0.
          lv_month = lines( lt_leave_temp ).
          LOOP AT lt_leave_cnt ASSIGNING <fs_bal> WHERE zmonth = lv_month.
            <fs_bal>-scl = 0.
            <fs_bal>-leave_date_scl = ls_param-from_date.
          ENDLOOP.
        ELSE.
          lv_no_balance = abap_true.
        ENDIF.

    ENDCASE.

    IF lv_no_balance = abap_true.
      " 034 Insufficient balance for &1. Leave cannot be applied.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky ) TO failed-zi_ts_hdr_gv.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky
                      %action-applyleave = if_abap_behv=>mk-on
                      %msg = new_message( id       = c_msg
                                          number   = '034'
                                          severity = if_abap_behv_message=>severity-error
                                          v1       = ls_param-timeoff_type ) )
             TO reported-zi_ts_hdr_gv.
      RETURN.
    ENDIF.

    ls_leave_his = VALUE #( timeid     = keys[ 1 ]-TimeId
                            emp_id     = keys[ 1 ]-EmpId
                            leave_type = ls_param-timeoff_type
                            startdate  = ls_param-from_date
                            period     = ls_param-Period
                            status     = 'Pending Approval' ).

    zcl_timesheet_management=>sent_mail_for_time_off(
      EXPORTING
        is_leave = ls_leave_his
      IMPORTING
        ev_send  = DATA(lv_send) ).

    IF lv_send <> abap_true.
      " 035 Leave email could not be sent. Request not submitted.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky ) TO failed-zi_ts_hdr_gv.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky
                      %action-applyleave = if_abap_behv=>mk-on
                      %msg = new_message( id       = c_msg
                                          number   = '035'
                                          severity = if_abap_behv_message=>severity-error ) )
             TO reported-zi_ts_hdr_gv.
      RETURN.
    ENDIF.

    " ---- mail sent -> now save balance and leave request
    UPDATE zrap_leave_bal FROM TABLE @lt_leave_cnt.

    DELETE FROM zrap_leave_his WHERE timeid    = @( keys[ 1 ]-TimeId )
                                 AND emp_id    = @( keys[ 1 ]-EmpId )
                                 AND startdate = @ls_leave_his-startdate.

    MODIFY zrap_leave_his FROM @ls_leave_his.

    IF sy-subrc IS INITIAL.
      " 036 Leave request for &1 (&2) submitted for approval.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky
                      %msg = new_message( id       = c_msg
                                          number   = '036'
                                          severity = if_abap_behv_message=>severity-success
                                          v1       = |{ ls_param-from_date DATE = ENVIRONMENT }|
                                          v2       = ls_param-timeoff_type ) )
             TO reported-zi_ts_hdr_gv.
    ENDIF.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr1).

    result = VALUE #( FOR ls_hdr IN lt_hdr1 ( %tky   = ls_hdr-%tky
                                              %param = ls_hdr ) ).

  ENDMETHOD.

  METHOD resubmitforapproval.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr).

    IF lt_hdr IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      UPDATE FIELDS ( Status Attchement Filename )
      WITH VALUE #( FOR ls_hdr IN lt_hdr ( %tky       = ls_hdr-%tky
                                           Status     = 'Created'
                                           Attchement = ''
                                           Filename   = '' ) ).

    LOOP AT lt_hdr INTO DATA(ls_hdr1).
      DELETE FROM zrap_appr_gv WHERE time_id = @ls_hdr1-TimeId
                                 AND emp_id  = @ls_hdr1-EmpId.

      " 026 Timesheet reset to Created. Edit and submit it again.
      APPEND VALUE #( %tky = ls_hdr1-%tky
                      %msg = new_message( id       = c_msg
                                          number   = '026'
                                          severity = if_abap_behv_message=>severity-success ) )
             TO reported-zi_ts_hdr_gv.
    ENDLOOP.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr1).

    result = VALUE #( FOR ls_res IN lt_hdr1 ( %tky   = ls_res-%tky
                                              %param = ls_res ) ).

  ENDMETHOD.

  METHOD approved.

    DATA(lv_user) = zcl_timesheet_management=>get_memory_id( ).

    DATA:
      lv_monthly_ctc TYPE p LENGTH 12 DECIMALS 2,
      lv_basic       TYPE p LENGTH 12 DECIMALS 2,
      lv_hra         TYPE p LENGTH 12 DECIMALS 2,
      lv_project     TYPE p LENGTH 12 DECIMALS 2,
      lv_additional  TYPE p LENGTH 12 DECIMALS 2,
      lv_pf          TYPE p LENGTH 12 DECIMALS 2,
      lv_health      TYPE p LENGTH 12 DECIMALS 2,
      lv_variable    TYPE p LENGTH 12 DECIMALS 2.


    SELECT  FROM zrap_emp_gv
      FIELDS emp_id,anuval_ctc,email
      INTO  TABLE @DATA(lt_emp).
    DATA(lv_appr_id) = VALUE #( lt_emp[ email = lv_user ]-emp_id OPTIONAL ).
    IF lv_appr_id IS INITIAL.
      " 031 Approver not found for the logged-in user. Please log in again.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky ) TO failed-zi_ts_hdr_gv.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky
                      %msg = new_message( id       = c_msg
                                          number   = '031'
                                          severity = if_abap_behv_message=>severity-error ) )
             TO reported-zi_ts_hdr_gv.
      RETURN.
    ENDIF.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr).

    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR ls_hrd IN lt_hdr ( %tky   = ls_hrd-%tky
                                           Status = 'Approved' ) ).
    SELECT FROM zrap_project_gv
    FIELDS * INTO TABLE @DATA(lt_project).

    SELECT FROM zrap_expenses
    FIELDS * INTO TABLE @DATA(lt_expenses).

    LOOP AT lt_hdr INTO DATA(ls_hdr).
      DATA(ls_header) = VALUE zgo_s_payslipheader( name = ls_hdr-emp_name
                           month = |{ ls_hdr-Zmonth+0(3) }'{ ls_hdr-StartDate+2(2) }|
                           date_from = |{ ls_hdr-StartDate DATE = ISO }|
                           date_to = |{ ls_hdr-EndDate DATE = ISO }|
                           designation = ls_hdr-designation
                           identification_no = ls_hdr-EmpId
                            ).
      DATA(lv_overall_ctc) = VALUE #( lt_emp[ emp_id = ls_hdr-EmpId ]-anuval_ctc OPTIONAL ).
      IF lv_overall_ctc IS NOT INITIAL.
        "Convert Annual CTC to Monthly CTC

*        lv_monthly_ctc = lv_ctc / 12.
*
        lv_variable = lv_overall_ctc * 10 / 100.
        lv_health = ( 833 * 12 ).
        DATA(lv_emp_pf) = ( 1800 * 12 ) .
        DATA(lv_ctc) = ( lv_overall_ctc - ( lv_variable + lv_health + lv_emp_pf ) ).
        lv_monthly_ctc = lv_ctc / 12.

        "      "Basic Salary - 45%
        lv_basic = lv_monthly_ctc * '55.3541' / 100.

        "HRA - 25%
        lv_hra = lv_monthly_ctc * '30.7523' / 100.

        "Project Allowance - 7.2727%
        lv_project = lv_monthly_ctc * '8.9461' / 100.

        "Additional Allowance - 4.0220%
        lv_additional = lv_monthly_ctc * '4.9475' / 100.

        "Employer PF - Fixed Rs. 1,800
        lv_pf = -1800.

        DATA(lv_no_project) = xsdbool( NOT line_exists( lt_project[ emp_id = ls_hdr-EmpId ] ) ).
        DATA(lv_travel_amt) = REDUCE #( INIT total = CONV decfloat34( 0 ) FOR ls_exp IN lt_expenses
                              WHERE ( status = 'Approved' AND emp_id = ls_hdr-EmpId AND timeid = ls_hdr-TimeId ) NEXT total = total + ls_exp-total_amt ).
        DATA(ls_item) = VALUE zgo_s_payslipitem( basic_salary = lv_basic
                           hra = lv_hra
                           project_allowance = lv_project
                           additional_allowance = lv_additional
                           employee_pf = lv_pf
                           professional_tax = '-208'
                           travel_allowance = lv_travel_amt
                           project_deduction = COND #( WHEN lv_no_project = abap_true
                                                       THEN ( -1 * ( lv_project ) ) ) ).
      ENDIF.
      DATA(lv_pay_xstring) = zcl_timesheet_management=>get_payslip(
                         is_header = ls_header
                         is_item   = ls_item
                       ).
      DATA(ls_pay_att) = VALUE zrap_attach_gv(
          time_id = ls_hdr-TimeId
          emp_id = ls_hdr-EmpId
          attchement = lv_pay_xstring
          mine_type  = 'application/pdf'
          filename   = |{ ls_hdr-emp_name }-{ ls_hdr-Zmonth }-Payslip.pdf|   ) .
      MODIFY zrap_attach_gv FROM ls_pay_att .

      UPDATE zrap_appr_gv
         SET status  = 'Approved',
             a_comm  = 'Approved',
             d_apprv = @sy-datum,
             t_apprv = @sy-uzeit
       WHERE time_id = @ls_hdr-TimeId
         AND emp_id  = @ls_hdr-EmpId
         AND appr_id = @lv_appr_id.

      " 029 Timesheet approved by Finance.
      APPEND VALUE #( %tky = ls_hdr-%tky
                      %msg = new_message( id       = c_msg
                                          number   = '029'
                                          severity = if_abap_behv_message=>severity-success ) )
             TO reported-zi_ts_hdr_gv.
    ENDLOOP.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr1).

    result = VALUE #( FOR ls_hrd1 IN lt_hdr1 ( %tky   = ls_hrd1-%tky
                                               %param = ls_hrd1 ) ).

  ENDMETHOD.

  METHOD rejected.

    DATA(lv_user) = zcl_timesheet_management=>get_memory_id( ).

    SELECT SINGLE FROM zrap_emp_gv
      FIELDS emp_id
      WHERE email = @lv_user
      INTO @DATA(lv_appr_id).

    IF sy-subrc <> 0.
      " 031 Approver not found for the logged-in user. Please log in again.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky ) TO failed-zi_ts_hdr_gv.
      APPEND VALUE #( %tky = keys[ 1 ]-%tky
                      %msg = new_message( id       = c_msg
                                          number   = '031'
                                          severity = if_abap_behv_message=>severity-error ) )
             TO reported-zi_ts_hdr_gv.
      RETURN.
    ENDIF.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr).

    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR ls_hrd IN lt_hdr ( %tky   = ls_hrd-%tky
                                           Status = 'Rejected' ) ).

    LOOP AT lt_hdr INTO DATA(ls_hdr).
      UPDATE zrap_appr_gv
         SET status  = 'Rejected',
             a_comm  = 'Rejected',
             d_apprv = @sy-datum,
             t_apprv = @sy-uzeit
       WHERE time_id = @ls_hdr-TimeId
         AND emp_id  = @ls_hdr-EmpId
         AND appr_id = @lv_appr_id.

      " 030 Timesheet rejected by Finance.
      APPEND VALUE #( %tky = ls_hdr-%tky
                      %msg = new_message( id       = c_msg
                                          number   = '030'
                                          severity = if_abap_behv_message=>severity-success ) )
             TO reported-zi_ts_hdr_gv.
    ENDLOOP.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr1).

    result = VALUE #( FOR ls_hrd1 IN lt_hdr1 ( %tky   = ls_hrd1-%tky
                                               %param = ls_hrd1 ) ).

  ENDMETHOD.

  METHOD expenses.


    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_hdr_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr).
    DATA(ls_expenses) = VALUE zrap_expenses( timeid = lt_hdr[ 1 ]-TimeId
                                             emp_id = lt_hdr[ 1 ]-EmpId
                                             ex_date = keys[ 1 ]-%param-ex_date
                                             category = keys[ 1 ]-%param-category
                                             description = keys[ 1 ]-%param-category
                                             paid_by = COND #( WHEN  keys[ 1 ]-%param-employee_paid = abap_true
                                                               THEN 'Employee'
                                                               ELSE 'Company' )
                                             status = 'Pending'
                                             total_amt = keys[ 1 ]-%param-Total   ).
    IF ls_expenses IS NOT INITIAL.
      MODIFY zrap_expenses FROM ls_expenses.
    ENDIF.
    result = VALUE #( FOR ls_hdr IN lt_hdr ( %tky   = ls_hdr-%tky
                                             %param = ls_hdr ) ).

  ENDMETHOD.

*======================================================================*
* DAILY ENTRY ACTIONS
*======================================================================*
  METHOD checkin.

    DATA(lv_time) = cl_abap_context_info=>get_system_time( ).

    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_item_gv
      UPDATE FIELDS ( Zdate Checkin_time checkout_time Status )
      WITH VALUE #( FOR ls_key IN keys ( %tky          = ls_key-%tky
                                         Checkin_time  = lv_time
                                         Zdate         = sy-datum
                                         checkout_time = '000000'
                                         Status        = 'Pending' ) )
      REPORTED DATA(lt_repot).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_item_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    LOOP AT lt_item INTO DATA(ls_item).
      " 041 Checked in at &1.
      APPEND VALUE #( %tky = ls_item-%tky
                      %msg = new_message( id       = c_msg
                                          number   = '041'
                                          severity = if_abap_behv_message=>severity-success
                                          v1       = |{ lv_time TIME = ISO }| ) )
             TO reported-zi_ts_item_gv.
    ENDLOOP.

    result = VALUE #( FOR ls_res IN lt_item ( %tky   = ls_res-%tky
                                              %param = ls_res ) ).

  ENDMETHOD.

  METHOD checkout.

    DATA lv_hours   TYPE zrap_ts_item-zhours.
    DATA lv_seconds TYPE i.
    DATA lt_update  TYPE TABLE FOR UPDATE zi_ts_item_gv.

    DATA(lv_now) = cl_abap_context_info=>get_system_time( ).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_item_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item1).

    LOOP AT lt_item1 INTO DATA(ls_item1).

      IF ls_item1-Checkin_time IS INITIAL.
        " 042 Check in first before checking out.
        APPEND VALUE #( %tky = ls_item1-%tky ) TO failed-zi_ts_item_gv.
        APPEND VALUE #( %tky = ls_item1-%tky
                        %msg = new_message( id       = c_msg
                                            number   = '042'
                                            severity = if_abap_behv_message=>severity-error ) )
               TO reported-zi_ts_item_gv.
        CONTINUE.
      ENDIF.

      lv_seconds = lv_now - ls_item1-Checkin_time.
      lv_hours   = lv_seconds / 3600.

      APPEND VALUE #( %tky          = ls_item1-%tky
                      checkout_time = lv_now
                      Zhours        = lv_hours ) TO lt_update.

      " 043 Checked out at &1. Hours worked: &2.
      APPEND VALUE #( %tky = ls_item1-%tky
                      %msg = new_message( id       = c_msg
                                          number   = '043'
                                          severity = if_abap_behv_message=>severity-success
                                          v1       = |{ lv_now TIME = ISO }|
                                          v2       = |{ lv_hours }| ) )
             TO reported-zi_ts_item_gv.
    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
        ENTITY zi_ts_item_gv
        UPDATE FIELDS ( checkout_time Zhours )
        WITH lt_update
        REPORTED DATA(lt_repot).
    ENDIF.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_item_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    result = VALUE #( FOR ls_res IN lt_item ( %tky   = ls_res-%tky
                                              %param = ls_res ) ).

  ENDMETHOD.

  METHOD approve.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_item_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_item_gv
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR ls_item IN lt_item ( %tky   = ls_item-%tky
                                             Status = 'Approved' ) ).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_item_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item1).

    LOOP AT lt_item1 INTO DATA(ls_item1).
      " 044 Daily entry for &1 approved.
      APPEND VALUE #( %tky = ls_item1-%tky
                      %msg = new_message( id       = c_msg
                                          number   = '044'
                                          severity = if_abap_behv_message=>severity-success
                                          v1       = |{ ls_item1-Zdate DATE = ENVIRONMENT }| ) )
             TO reported-zi_ts_item_gv.
    ENDLOOP.

    result = VALUE #( FOR ls_res IN lt_item1 ( %tky   = ls_res-%tky
                                               %param = ls_res ) ).

  ENDMETHOD.

  METHOD reject.

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_item_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    MODIFY ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_item_gv
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR ls_item IN lt_item ( %tky   = ls_item-%tky
                                             Status = 'Rejected' ) ).

    READ ENTITIES OF zi_ts_hdr_gv IN LOCAL MODE
      ENTITY zi_ts_item_gv
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item1).

    DATA(ls_reject) = VALUE zrap_reject( time_id = lt_item1[ 1 ]-TimeId
                                         emp_id  = lt_item1[ 1 ]-EmpId
                                         status  = lt_item1[ 1 ]-Status
                                         reason  = keys[ 1 ]-%param-remarks ).
    MODIFY zrap_reject FROM @ls_reject.

    LOOP AT lt_item1 INTO DATA(ls_item1).
      " 020 Timesheet rejected. Reason: &1
      APPEND VALUE #( %tky = ls_item1-%tky
                      %msg = new_message( id       = c_msg
                                          number   = '020'
                                          severity = if_abap_behv_message=>severity-success
                                          v1       = keys[ 1 ]-%param-remarks ) )
             TO reported-zi_ts_item_gv.
    ENDLOOP.

    result = VALUE #( FOR ls_res IN lt_item1 ( %tky   = ls_res-%tky
                                               %param = ls_res ) ).

  ENDMETHOD.

  METHOD get_instance_authorizations_1.
  ENDMETHOD.

ENDCLASS.
