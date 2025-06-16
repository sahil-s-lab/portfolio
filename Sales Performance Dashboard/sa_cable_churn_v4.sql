
select  w1.employee_name,
w2.manager_level_1,
w2.channel,
w1.wireless_id as channel_id,
dwop.rep_employee_sgi as sgi_id,
hr1.employee_id as employee_id,
(sub.first_name||' '||sub.surname) as last_business_name,---Last business Name,
to_number(sub.ban_num) as ban, --ban
null as subscriber_no,
DWOP.COMPANY_NUMBER||WO.ACCOUNT_NUMBER as cable_no,
to_char(DWOP.REPORT_DATE, 'mm/dd/yyyy') as Report_Date,
DWOP.PRODUCT_QUANTITY * -1 as units,
case when prod_keys.product_family = 'INTERNET' then 
	case when prod_keys.product_code in ('WDJM', 'WDJG', 'WDJK', 'WDJE', 'W5DS', 'WBGB', 'WCJE', 'WCJF', 'WD5P', 'WDB5', 'WDJB', 'WDJD', 'WGBB','WDJF','WDJL') then -150
		when prod_keys.product_code in ('WCJD', 'WD1P', 'WDB1', 'WDJA', 'WDJC') then -100
		else -75 end    
  when prod_keys.product_family = 'PHONE' then -25
  when prod_keys.product_family = 'TV' then -50
  when prod_keys.product_family = 'SBM' then -40
  else 0 end as rate,--rate
prod_keys.product_Family as type,
'Small' as segment, --segment
PRD.PRODUCT_DESCRIPTION, --Pplan_Series_Desc
'Churn' as sale_type,
w3.attribute_value 

FROM MARQUEE_OWNER.WORK_ORDER WO 
left join MARQUEE_OWNER.DAILY_WORK_ORDER_PRODUCTS DWOP on DWOP.WORK_ORDER_KEY = WO.WORK_ORDER_KEY
LEFT JOIN MARQUEE_OWNER.HRXPRESS_EMP_MASTER HR1 ON DWOP.PROD_COMM_EMPLOYEE_HRXEMP_ID = HR1.HRXPRESS_EMP_UNIQUE_ID
join MARQUEE.ADDRESS ADDR on ADDR.ADDRESS_SEQ = DWOP.ADDRESS_SEQ
join MARQUEE.franchise FRAN on FRAN.FRANCHISE_KEY = WO.FRANCHISE_KEY
join MARQUEE.BIS_PRODUCT PRD  on PRD.PRODUCT_KEY = DWOP.PRODUCT_KEY
join MARQUEE.BIS_PRODUCT_MODEL_XREF x on x.PRODUCT_CODE = PRD.PRODUCT_CODE
  and x.MODEL_NAME = 'CHRNPROD'
JOIN MARQUEE.SUBSCRIBER SUB ON DWOP.SUBSCRIBER_SEQ = SUB.SUBSCRIBER_SEQ 
    AND SUB.COMM_BILL_ENTITY IS NULL
join (select b.product_code,
			b.product_key as PRODUCT_KEY,
            case when d.product_report_category_desc in ('RHPc SOHO Service Packages','IBLc Primary Service') then 'PHONE'
              when e.product_report_group_desc in ('Internet SBM Services') then 'INTERNET'
              when e.product_report_group_desc in ('Basic Services') then 'TV'
              when e.product_report_group_desc in ('RSHM Services') then 'SBM' 
              else null end as product_family,
            case when b.product_code = 'WSBB' then 'Rogers Ignite 30 for Business'
              when b.product_code = 'WSSB' then 'Rogers Ignite 60 for Business'
              when b.product_code = 'WSPR' then 'Rogers Ignite 100 for Businses'
              when b.product_code = 'WLBE' then 'Rogers Ignite 150 for Business'
              when b.product_code = 'WHBE' then 'Rogers Ignite 250 for Business'
              when b.product_code = 'W1DS' then 'Rogers Ignite 60 for Business + 1 Static IP'
              when b.product_code = 'W5DS' then 'Rogers Ignite 60 for Business + 5 Static IP'
              when b.product_code = 'WD1P' then 'Rogers Ignite 100 for Business + 1 Static IP'
              when b.product_code = 'WD5P' then 'Rogers Ignite 100 for Business + 5 Static IP'
              when b.product_code = 'WDB1' then 'Rogers Ignite 150 for Business + 1 Static IP'
              when b.product_code = 'WDB5' then 'Rogers Ignite 150 for Business + 5 Static IP'
              when b.product_code = 'WBGB' then 'Rogers Ignite 1 Gigabit'
              else b.product_description end as PRODUCT_DESCRIPTION
          from marquee.bis_product_model_xref a
          left join marquee.bis_product b on a.product_code = b.product_code
          left join marquee.bis_product_group c on b.product_group_code = c.product_group_code
          left join marquee.bis_product_report_category d on a.product_report_category_code = d.product_report_category_code
          left join marquee.bis_product_report_group e on d.product_report_group_code = e.product_report_group_code
          where a.model_name = 'CHRNPROD') prod_keys on dwop.product_key = prod_keys.product_key
            and prod_keys.product_family is not null
            
left join wl815963.employee w1 on hr1.employee_id = w1.employee_number

left join wl815963.employee_detail w2 on w1.id = w2.parent_id
  and w2.effective_start_date <= DWOP.REPORT_DATE
  and (w2.effective_end_date >= DWOP.REPORT_DATE )
  
  left join wl815963.employee_attribute w3 on w1.id = w3.parent_id
  and w3.effective_start_date <= DWOP.REPORT_DATE
  and (w3.effective_end_date >= DWOP.REPORT_DATE )
  and w3.attribute_name = 'Employee Type' 

where DWOP.WO_STATUS_KEY = 102
and DWOP.WO_TYPE_KEY in (112,113,116,117,118)  --removed 111 'change of service'
and DWOP.REPORT_DATE >= to_date('2018-01-01','YYYY-MM-DD')
and DWOP.DWOP_ORDER_STATUS='D' 
and DWOP.CANCEL_IND = 0 
and DWOP.INCLUDE_IN_CHURN_FLAG ='Y'
and WO.SERVICABILITY_CODE <> 'D'
and DWOP.ADDRESS_SEQ <> 10
and (prod_keys.product_family = 'TV' and addr.contract_group_code = 5
  or (prod_keys.product_family in ('PHONE','INTERNET','SBM')))
and DWOP.REPORT_DATE - DWOP.PROD_START_BILL_DATE <= 135
And Exists (Select 1 From Wl815963.employee w1 
	join Wl815963.employee_detail w2 on w1.id = w2.parent_id
	Where w1.employee_number = hr1.employee_id and (w2.channel IN ('Field Sales','Small - NIS','Lake Shore')))
;