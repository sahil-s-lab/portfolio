SELECT w2.employee_name,
w2.manager_level_1,
w2.channel,
a.sub_CHANNEL_ID as channel_id,
w2.cable_id as sgi_id ,
w2.employee_number as employee_id,
ba.last_business_name as business_name,
a.ban,
a.SUBSCRIBER_NO,
null as Cable_no,
case when a.activation > 0 then to_char(a.init_activation_date, 'mm/dd/yyyy')
	when a.last_act = 'CA' and s.deactivation_date is not null then to_char(s.deactivation_date,'mm/dd/yyyy')
	else to_char(a.sub_status_issue_date,'mm/dd/yyyy') end as report_date,
case when a.activation > 0 or a.resume_non_churn > 0 then 1
	when a.last_act = 'CA' and s.deactivation_date is not null then -1 
	else 0 end as units,
case when a.activation > 0 or a.resume_non_churn > 0 then
	case when s.payee_ind in ('M','N') then pp.rate  
		else pp.secondary_amount end
	when a.last_act = 'CA' and s.deactivation_date is not null then
		case when s.payee_ind in ('M','N') then -1*pp2.rate
			else -1*pp2.secondary_amount end
	else 0 end as rate,
case when a.pplan_group_cd in ('WHPS','WHPC') then 'WBP'
	when a.pplan_series_type = 5 then 'MBB'
	else 'VOICE' end as Type,
csseg.segment_desc,
soc.soc_description as description,
case when a.activation > 0 or a.resume_non_churn > 0 then 'Activation' else 'Churn' end as sale_type,
w3.attribute_value

FROM ods.MSP_ACTIVITY_HIST a
/* Add segment data*/
left join ods.cs_acct_segment seg on a.BAN = seg.ban and seg.crnt_ind = 'Y'
  left join ods.cs_segment csseg on seg.segment_skey = csseg.segment_skey
  
join ods.subscriber s on a.ban = s.customer_ban
  and s.subscriber_no = a.subscriber_no

/*Activaiton MRR*/
left join ods.pp_rc_rate pp on a.soc = pp.soc
    and pp.rate >= 1
    and pp.suspension_amount > 0
    and pp.effective_date <= a.sub_status_issue_date 
    and (pp.expiration_date > a.sub_status_issue_date or pp.expiration_date is null)
    and (a.activation > 0 or a.resume_non_churn > 0)
    
/*Churn MRR*/
left join (select spp.*,
	row_number() over (partition by spp.ban, spp.subscriber_no order by spp.effective_issue_date asc) as row_num
	from ods.subscriber_price_plan spp) spp on coalesce(s.prv_ban,a.ban) = spp.ban 
	  and coalesce(s.prv_Ctn,a.subscriber_no) = spp.subscriber_no
	  and a.last_act = 'CA'
	  and spp.effective_date <= s.init_activation_date
	  and spp.row_num = 1
  left join ods.pp_rc_rate pp2 on spp.soc = pp2.soc
    and pp2.rate >= 1
    and pp2.suspension_amount > 0
    and pp2.effective_date <= spp.effective_date 
    and (pp2.expiration_date > spp.effective_date or pp2.expiration_date is null)

left join ods.billing_account BA on a.ban = ba.ban

  left join wl815963.employee_detail w2 on a.sub_channel_id = w2.wireless_id
  and w2.effective_start_date <= a.sub_status_issue_date
  and (w2.effective_end_date >= a.sub_status_issue_date )
  
  left join wl815963.employee_attribute w3 on a.sub_channel_id = w3.wireless_id
  and w3.effective_start_date <= a.sub_status_issue_date
  and (w3.effective_end_date >= a.sub_status_issue_date )
  and w3.attribute_name = 'Employee Type' 

  
left join ods.soc soc on a.soc = soc.soc
  and soc.effective_date <= a.init_activation_date
  and (soc.expiration_date > a.init_activation_date or soc.expiration_date is null)

where a.msp_year in 2018
  and a.msp_month in (1)
  AND a.pplan_series_type in (1,5)
AND (a.activation > 0 
	or (a.last_act = 'CA' and  a.deactivation_date - a.init_activation_date <= 90)
	or (a.last_act = 'RC' and a.resume_non_churn > 0))
  And Exists (Select 1 From Wl815963.employee_detail w2
	Where w2.Wireless_Id = A.Sub_Channel_Id and (w2.channel IN ('Field Sales','Small - NIS','Lake Shore')))

-------------------------------------------------------
 union all --Cable sales details
-------------------------------------------------------
 SELECT w2.employee_name,
w2.manager_level_1,
w2.channel,
w2.wireless_id,
dwop.rep_employee_sgi,
hr1.employee_id as employee_id,
(sub.first_name||' '||sub.surname) as last_business_name,---Last business Name,
to_number(sub.ban_num) as ban, --ban
null as subscriber_no, --subscriber_no
DWOP.COMPANY_NUMBER||WO.ACCOUNT_NUMBER as cable_no,
to_char(DWOP.REPORT_DATE,'mm/dd/yyyy') report_date, 
DWOP.PRODUCT_QUANTITY,
case when prd.product_code = 'BCAB' and (addr.contract_type_code = '2N1' or addr.rate_area = 'PR ') then 37.49
  else coalesce(ppp.prod_rate,ppp2.prod_rate,ppp3.prod_rate) end as rate,
prod_keys.product_family, --Type
'Small' as segment, --segment
PRD.PRODUCT_DESCRIPTION, --Pplan_Series_Desc
'Activation' as sale_type,
w3.attribute_value

FROM MARQUEE_OWNER.DAILY_WORK_ORDER_PRODUCTS DWOP
  LEFT JOIN MARQUEE_OWNER.HRXPRESS_EMP_MASTER HR1 ON DWOP.PROD_COMM_EMPLOYEE_HRXEMP_ID = HR1.HRXPRESS_EMP_UNIQUE_ID
  LEFT JOIN MARQUEE.BIS_PRODUCT PRD ON DWOP.PRODUCT_KEY = PRD.PRODUCT_KEY
  LEFT JOIN MARQUEE.BIS_PRODUCT_GROUP PRDGR ON PRD.PRODUCT_GROUP_CODE = PRDGR.PRODUCT_GROUP_CODE
  JOIN MARQUEE.SUBSCRIBER SUB ON DWOP.SUBSCRIBER_SEQ = SUB.SUBSCRIBER_SEQ 
    AND SUB.COMM_BILL_ENTITY IS NULL
  JOIN MARQUEE_OWNER.WORK_ORDER WO ON WO.WORK_ORDER_KEY = DWOP.WORK_ORDER_KEY 
    AND WO.COMPANY_NUMBER = DWOP.COMPANY_NUMBER
  JOIN MARQUEE.CONTRACT_TYPE CT ON WO.CONTRACT_TYPE_KEY = CT.CONTRACT_TYPE_KEY 
    AND WO.COMPANY_NUMBER = CT.COMPANY_NUMBER
  LEFT JOIN MARQUEE.ADDRESS ADDR ON DWOP.ADDRESS_SEQ = ADDR.ADDRESS_SEQ
  LEFT JOIN MARQUEE.ADDRESS_POSTAL ADDRP ON ADDR.POSTAL_ZIP_CODE = ADDRP.POSTAL_CD
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

LEFT JOIN MARQUEE.ADDRESS ADDR ON DWOP.ADDRESS_SEQ = ADDR.ADDRESS_SEQ

 -- method using product_rate table but most product codes show as $0 
left join (select company_number,
  product_cd,
  contract_type_cd,
  rate_area,
  case when prod_rate = 0 then null else prod_rate end prod_rate,
  lag(rate_end_dt) over (partition by product_cd,contract_type_cd,rate_area order by rate_end_dt) sta_dt,
  rate_end_dt as end_dt
  from marquee_owner.product_price_plan
  ) ppp on dwop.company_number = ppp.company_number
  and prod_keys.product_code = ppp.product_cd
  and addr.contract_type_code = ppp.contract_type_cd
  and addr.rate_area = ppp.rate_area
  and dwop.report_date >= coalesce(ppp.sta_dt,to_date('01/01/1901','mm/dd/yyyy'))
  and dwop.report_date < ppp.end_dt
  
--run back through the product_rate table and join where rate_area is null and contract_type_code is null and use company_number 'SSS'
left join (select company_number,
  product_cd,
  contract_type_cd,
  rate_area,
  case when prod_rate = 0 then null else prod_rate end prod_rate,
  lag(rate_end_dt) over (partition by product_cd,contract_type_cd,rate_area order by rate_end_dt) sta_dt,
  rate_end_dt as end_dt
  from marquee_owner.product_price_plan
  where contract_type_cd is null
  and rate_area is null
  and company_number = 'SSS'
  ) ppp2 on prod_keys.product_code = ppp2.product_cd
  and dwop.report_date >= coalesce(ppp2.sta_dt,to_date('01/01/1901','mm/dd/yyyy'))
  and dwop.report_date < ppp2.end_dt

--run back through the product_rate table and match to anchor_code on marquee.subscriber_product
left join (select distinct subscriber_seq,
  address_seq,
  subscriber_address_seq
  from marquee.subscriber_address) sub_addr on dwop.subscriber_seq = sub_addr.subscriber_seq
  and dwop.address_seq = sub_addr.address_seq

left join (select distinct sub_prd.anchor_code,
  sub_prd.product_code,
  sub_prd.subscriber_address_seq,
  row_number() over (partition by sub_prd.product_code,  sub_prd.subscriber_address_seq order by sub_prd.start_bill_date desc) as row_num
  from marquee.subscriber_product sub_prd) sub_prd on sub_addr.subscriber_address_seq = sub_prd.subscriber_address_seq
  and prod_keys.product_code = sub_prd.product_code
  and row_num = 1 --remove where multiple anchor code, product code combos are used

left join (select distinct product_cd,
  case when prod_rate = 0 then null else prod_rate end prod_rate,
  lag(rate_end_dt) over (partition by product_cd,contract_type_cd,rate_area order by rate_end_dt) sta_dt,
  rate_end_dt as end_dt
  from marquee_owner.product_price_plan
  where contract_type_cd is null
  and rate_area is null
  and company_number = 'SSS'
  ) ppp3 on sub_prd.anchor_code = ppp3.product_cd
  and dwop.report_date >= coalesce(ppp3.sta_dt,to_date('01/01/1901','mm/dd/yyyy'))
  and dwop.report_date < ppp3.end_dt
  and ppp3.sta_dt != ppp3.end_dt

left join wl815963.employee_detail w2 on hr1.employee_id = w2.employee_number
  and w2.effective_start_date <= DWOP.REPORT_DATE
  and (w2.effective_end_date >= DWOP.REPORT_DATE )
  
left join wl815963.employee_attribute w3 on hr1.employee_id = w3.employee_number
  and w3.effective_start_date <= DWOP.REPORT_DATE
  and (w3.effective_end_date >= DWOP.REPORT_DATE )
  and w3.attribute_name = 'Employee Type' 

WHERE DWOP.REPORT_DATE >= to_date('2018-01-01','YYYY-MM-DD')
AND DWOP.SALES_TYPE IN ('N','P')
and (prod_keys.product_family = 'TV' and addr.contract_group_code = 5
  or (prod_keys.product_family in ('PHONE','INTERNET','SBM')))
AND DWOP.PROD_COMM_EMPLOYEE_SEQ IS NOT NULL
And Exists (Select 1 From Wl815963.employee_detail w2
	Where w2.employee_number = hr1.employee_id and (w2.channel IN ('Field Sales','Small - NIS','Lake Shore')))

-------------------------------------
--union all --RBAM sales deatils
-------------------------------------

select w2.employee_name,
w2.manager_level_1,
w2.channel,
c.dealer_code,
w2.cable_id, --Sgi
w2.employee_number, --employee_id
ba.last_business_name,
to_number(coalesce(c.business_account_number, substr(ciam.accounts,-9))) as BAN,
null as a_subscriber_no, --Subscriber_no
null as b_cable_no, --Cable_company_number
to_char(c.custom_date,'mm/dd/yyyy')custom_Date,
c.number_of_units,
c.price,
'RBAM',
csseg.segment_desc,
c.application_edition_name, --pplan_series_desc,
case when c.number_of_units > 0 then 'Activation' else 'Churn' end as sale_type,
w3.attribute_value

from ods_appdirect.custom c
left join (select guid,
  accounts,
  row_number() over (partition by substr(ciam.accounts,-9) order by creation_date desc) as row_num
  from ods_ciam.customer ciam
    where ciam.crnt_flg = 'Y') ciam on c.owner_external_id = ciam.guid
    and row_num = 1

/*Pull segment data*/ 

left join ods.cs_acct_segment seg on coalesce(c.business_account_number, substr(ciam.accounts,-9)) = seg.ban and seg.crnt_ind = 'Y'
  left join ods.cs_segment csseg on seg.segment_skey = csseg.segment_skey

left join ods.billing_account ba on coalesce(c.business_account_number, substr(ciam.accounts,-9)) = ba.ban

left join wl815963.employee_detail w2 on c.dealer_code = w2.wireless_id
  and w2.effective_start_date <= c.custom_date
  and (w2.effective_end_date >= c.custom_date )
  
left join wl815963.employee_attribute w3 on c.dealer_code = w3.wireless_id
  and w3.effective_start_date <= c.custom_date
  and (w3.effective_end_date >= c.custom_date )
  and w3.attribute_name = 'Employee Type' 

	
where (c.custom_date = c.date_of_original_sale or (extract (day from (c.custom_date - c.date_of_original_sale)) in (1,2)))
and c.custom_date >= to_date('2018-01-01','YYYY-MM-DD')
and (c.dealer_code not in ('TST99','OSRCP') or c.dealer_Code is null)
and c.crnt_flg = 'Y'
and c.unit_type in ('USER','FLAT')
and not (c.application_name = 'GoDaddy' and c.custom_date <= to_date('2016-10-11','YYYY-MM-DD'))
And Exists (Select 1 From Wl815963.employee_detail w2
	Where w2.wireless_id = c.dealer_code and (w2.channel IN ('Field Sales','Small - NIS','Lake Shore')))
	
;
-------------------------------------
--union all --addons
-------------------------------------


-------------------------------------
--union all --cable churn
-------------------------------------

------------------------------------
--union all --SBM
------------------------------------	

