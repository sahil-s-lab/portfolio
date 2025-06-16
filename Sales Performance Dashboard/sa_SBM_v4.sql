
SELECT w2.employee_name,
w2.manager_level_1,
w2.channel,
w2.wireless_id as channel_id,
w2.cable_id as sgi_id ,
to_number(fct.comm_employee_id,'999999') as employee_id,
ba.last_business_name as business_name, --ba.last_business_name as business_name,
sbm_ban.ban as ban, --a.ban,
null as subscriber_no,--a.SUBSCRIBER_NO,
sbm_ban.account_id as Cable_no,
to_char(fct.report_date,'mm/dd/yyyy') as report_date,
case when fct.activity_type in ('NA','RA','PA') then fct.prod_quantity
  else fct.prod_quantity *-1 end as units,
case when fct.activity_type in  ('NA','RA','PA') then
  case when fct.prod_ref_id = 'SS10' then 44.95
    when fct.prod_ref_id = 'SS11' then 51.94
    when fct.prod_ref_id = 'SS12' then 65.90
    else 0.00 end
  else case when fct.prod_ref_id = 'SS10' then -44.95
    when fct.prod_ref_id = 'SS11' then -51.94
    when fct.prod_ref_id = 'SS12' then -65.90
    else 0.00 end end as rate,
'SBM' as product_type,
csseg.segment_desc as segment,
prd.billing_offer as description,
case when fct.activity_type in ('NA','RA','PA') then 'Activation' else 'Churn' end as sale_type,
w3.attribute_value

from BPRVWS.VwLgcyProdTxnGrFct fct --teraprod.VwProdDim prd

left join BPRVWS.VwProdMPNGFD prd on fct.prod_ref_id = prd.prod_ref_id

left join wl815963.employee_detail w2 on fct.comm_employee_id = to_char(w2.employee_number)
  and w2.effective_start_date <= fct.report_date
  and (w2.effective_end_date >= fct.report_date )
  
left join wl815963.employee_attribute w3 on fct.comm_employee_id = to_char(w3.employee_number)
  and w3.effective_start_date <= fct.report_date
  and (w3.effective_end_date >= fct.report_date )
  and w3.attribute_name = 'Employee Type' 


left join (select customer_key,
  ap_id,
  account_id,
  ban,
  row_number() over (partition by customer_key,ap_id,ban order by lastmodified_date desc) row_num
  from app_maestro.pntrdly
  where ban is not null
  order by row_num) sbm_ban on fct.customer_key = sbm_ban.customer_key
  and sbm_ban.ap_id = fct.ap_id
  and sbm_ban.row_num = 1
left join ods.billing_account BA on sbm_ban.ban = ba.ban
left join ods.cs_acct_segment seg on sbm_ban.BAN = seg.ban and seg.crnt_ind = 'Y'
  left join ods.cs_segment csseg on seg.segment_skey = csseg.segment_skey
  
where fct.src_ind = 'B' /*Product*/
  and fct.order_type = 'CO' /*Confirmed orders*/
  and fct.ap_start_date between prd.eff_from and prd.eff_to /*Capturing subscriber activity based on the report date at the product level*/
  and fct.non_countable_ind = 0 /*Countable addresses*/
  and fct.kbi_activity_ind = 'I' /*Include in reporting*/
  and fct.prod_ref_id in ('SS06','SS08','SS10','SS11','SS12','SS13','SS14','SS15')  /*RSHM Service level Product codes*/
  --consumer codes ('KS01','KS02','KS06','KS08','KS10','KS11','KS12','KS13','KS14','KS15','KS16')
  and fct.report_date >= to_date('2018-01-01','YYYY-MM-DD')
  and fct.activity_type != 'CR' /*Exclude Collection Resume*/
  and (fct.activity_type in ('NA','RA','PA') 
    or (fct.activity_type in ('CD','PD','YD','BD') 
      and fct.assigned_prod_status = 'CE' 
      and fct.include_in_churn_flag = 'Y'))
	  And Exists (Select 1 From Wl815963.employee_detail w2
	Where to_char(w2.employee_number) = fct.comm_employee_id and (w2.channel IN ('Field Sales','Small - NIS','Lake Shore')))
	
	;