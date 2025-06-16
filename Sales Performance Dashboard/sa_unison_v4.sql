select employee_name, manager_level_1, channel, channel_id, sgi_id, employee_id, last_business_name, ban, subscriber_no, cable_no, report_date, Units, Rate, type, segment_desc, rev_category, sale_type, attribute_value
from (
select distinct w2.employee_name,
w2.manager_level_1,
w2.channel,
coalesce(remove_check.channel_id,sa.CHANNEL_ID) channel_id,
w2.cable_id as sgi_id, --sgi_id
w2.employee_number as employee_id,
ba.last_business_name, -- business name
sa.BAN,
sa.SUBSCRIBER_NO,
null as cable_no, -- cable_no
to_char(sa.effective_issue_date,'mm/dd/yyyy') as report_date,
case when rf.MOBILE > 0 or rf.OFFICE > 0 then 
    case when (sa.expiration_issue_date - sa.effective_issue_date >= 15 or sa.expiration_issue_date is null) then 1
      when (sa.expiration_issue_date - sa.effective_issue_date < 15 
          and to_char(sa.effective_issue_date,'mm') !=  to_char(sa.expiration_issue_date,'mm')) then 1
      else 0 end
  else 0 end as units, --checks whether the SOC has MOBILE/OFFICE "line" type features to count as a unit
case when rf.UCPNR1_CPNR1_one_time > 0 then 0
	when (sa.expiration_issue_date - sa.effective_issue_date >= 15 or sa.expiration_issue_date is null) then 1 * pp.rate
	when  (sa.expiration_issue_date - sa.effective_issue_date < 15 
		and to_char(sa.effective_issue_date,'mm') !=  to_char(sa.expiration_issue_date,'mm')) then 1 * pp.rate
  else 0 end as rate,
'UNISON' as type,
csseg.segment_desc,
case when sa.product_type = 'C' then --first level case statement checks if the soc type is MOBILE or OFFICE
    case when rf.UCPNR1_CPNR1_one_time > 0 then 'HYBRID_ONETIME' --second level case statement determines the type of charge
      when rf.MOBILE > 0 then 'MOBILE_LINE'
      else 'HYBRID_FEATURE' end --all other charge types are lumped as add-on features
  when sa.product_type = 'U' then 
    case when rf.UCPNR1_CPNR1_one_time > 0 then 'OFFICE_ONETIME'
      when rf.OFFICE > 0 then 'OFFICE_LINE'
      else 'OFFICE_FEATURE' end 
  end as rev_category,
'Activation' as sale_type,
w3.attribute_value,
ppg.pplan_series_type
  
from ODS.service_agreement sa
join ods.pp_rc_rate pp on sa.soc = pp.soc
    and pp.rate >= 1
    and pp.suspension_amount > 0
    and pp.effective_date <= sa.effective_date 
    and (pp.expiration_date > sa.effective_date or pp.expiration_date is null)
    
left join ods.cs_acct_segment seg on sa.ban = seg.ban and seg.crnt_ind = 'Y'
  left join ods.cs_segment csseg on seg.segment_skey = csseg.segment_skey


  
join ods.subscriber_price_plan spp on sa.ban = spp.ban --this join checks whether the price plan of the CTN is not a test
  and sa.subscriber_no = spp.subscriber_no
  and spp.effective_date <= sa.effective_date
  and (spp.expiration_date is null 
    or spp.expiration_date > sa.effective_date)
join ods.price_plan_group ppg on spp.soc = ppg.soc
  and ppg.pplan_series_type != 2
  -- pplan_series_type = 2 is non-revenue price plans, tests

left join (select rf.soc,rf.effective_date,rf.expiration_date,
  sum(case when rf.feature_code in ('UCCUSR','UCCENT') then 1 else 0 end) as MOBILE, --counts list of unique MOBILE feature_code identifiers
  sum(case when rf.feature_code in ('UC00XG','UC00XI','UC00XO') then 1 else 0 end) as OFFICE,--counts list of unique OFFICE feature_code identifiers
  sum(case when rf.feature_code like 'CPNR1%' or rf.feature_code like 'UCPNR1' then 1 else 0 end) as UCPNR1_CPNR1_one_time --counts list of unique MOBILE/OFFICE onetime charge feature_code identifiers
  from ods.rated_feature rf
  where rf.soc like 'UNI%'
  group by rf.soc,rf.effective_date,rf.expiration_date
  order by rf.soc,rf.effective_date) rf on sa.soc = rf.soc
    and rf.effective_date <= sa.effective_date 
    and (rf.expiration_date > sa.effective_date or rf.expiration_date is null)

/*check if the same SOC was added and removed from the BAN/CTN pair in the last 15 days using a different dealer code
then use the old dealer code and effective date in the select statement (will produce duplicates if the original sale date is around)*/
left join ods.service_agreement remove_check 
  
  on sa.ban = remove_check.ban
    and sa.subscriber_no = remove_check.subscriber_no
    and sa.soc = remove_check.soc
    and sa.effective_issue_date - remove_check.effective_issue_date < 15
    and sa.effective_issue_date > remove_check.effective_issue_date

join wl815963.employee_detail w2 on coalesce(remove_check.channel_id,sa.CHANNEL_ID) = w2.wireless_id
  and w2.effective_start_date <= sa.effective_date
  and (w2.effective_end_date >= sa.effective_date )
  and w2.channel IN ('Field Sales','Small - NIS','Lake Shore')
  
left join wl815963.employee_attribute w3 on coalesce(remove_check.channel_id,sa.CHANNEL_ID) = w3.wireless_id
  and w3.effective_start_date <= sa.effective_date
  and (w3.effective_end_date >= sa.effective_date )
  and w3.attribute_name = 'Employee Type' 

	
left join ods.billing_account ba on sa.ban = ba.ban

where sa.soc like 'UNI%'
and sa.channel_id not in ('TST99','OSRCP')
and sa.effective_issue_date >= to_date('2018-01-01','YYYY-MM-DD')
--And Exists (Select 1 From Wl815963.employee_detail w2 
--	Where w2.wireless_id = sa.channel_id and (w2.channel IN ('Field Sales','Small - NIS','Lake Shore','Commercial - NIS')))

/*and exists (select 1
  from ods.subscriber sub where product_type in ('C','U') and  sa.ban = sub.customer_ban --this distinct join removes duplicate BAN,CTN pairs
  and sa.subscriber_no = sub.subscriber_no) */
  --need to also figure out why ALS_IND is different between C and U product_type for the same BAN, SUB pair

------------------------------------
union all --Unison phase 2 price plan SOC activaitons
------------------------------------

select distinct w2.employee_name,
w2.manager_level_1,
w2.channel,
coalesce(remove_check.channel_id,sa.CHANNEL_ID) channel_id,
w2.cable_id as sgi_id, --sgi_id
w2.employee_number as employee_id,
ba.last_business_name, -- business name
sa.BAN,
sa.SUBSCRIBER_NO,
null as cable_no, -- cable_no
to_char(sa.effective_issue_date,'mm/dd/yyyy') as report_date,
case when rf.MOBILE > 0 or rf.OFFICE > 0 then 
    case when (sa.expiration_issue_date - sa.effective_issue_date >= 15 or sa.expiration_issue_date is null) then 1
      when (sa.expiration_issue_date - sa.effective_issue_date < 15 
          and to_char(sa.effective_issue_date,'mm') !=  to_char(sa.expiration_issue_date,'mm')) then 1
      else 0 end
  else 0 end as units, --checks whether the SOC has MOBILE/OFFICE "line" type features to count as a unit
case when rf.UCPNR1_CPNR1_one_time > 0 then 0
	when (sa.expiration_issue_date - sa.effective_issue_date >= 15 or sa.expiration_issue_date is null) then 1 * pp.rate
	when  (sa.expiration_issue_date - sa.effective_issue_date < 15
		and to_char(sa.effective_issue_date,'mm') !=  to_char(sa.expiration_issue_date,'mm')) then 1 * pp.rate
  else 0 end as rate,
'UNISON' as type,
csseg.segment_desc,
case when sa.product_type = 'C' then --first level case statement checks if the soc type is MOBILE or OFFICE
    case when rf.UCPNR1_CPNR1_one_time > 0 then 'HYBRID_ONETIME' --second level case statement determines the type of charge
      when rf.MOBILE > 0 then 'MOBILE_LINE'
      else 'HYBRID_FEATURE' end --all other charge types are lumped as add-on features
  when sa.product_type = 'U' then 
    case when rf.UCPNR1_CPNR1_one_time > 0 then 'OFFICE_ONETIME'
      when rf.OFFICE > 0 then 'OFFICE_LINE'
      else 'OFFICE_FEATURE' end 
  end as rev_category,
'Activation' as sale_type,
w3.attribute_value,
ppg.pplan_series_type
  
from ODS.subscriber_price_plan sa
join ods.pp_rc_rate pp on sa.soc = pp.soc
    and pp.rate >= 1
    and pp.suspension_amount > 0
    and pp.effective_date <= sa.effective_date 
    and (pp.expiration_date > sa.effective_date or pp.expiration_date is null)
    
left join ods.cs_acct_segment seg on sa.ban = seg.ban and seg.crnt_ind = 'Y'
  left join ods.cs_segment csseg on seg.segment_skey = csseg.segment_skey

  
join ods.subscriber_price_plan spp on sa.ban = spp.ban --this join checks whether the price plan of the CTN is not a test
  and sa.subscriber_no = spp.subscriber_no
  and spp.effective_date <= sa.effective_date
  and (spp.expiration_date is null 
    or spp.expiration_date > sa.effective_date)
join ods.price_plan_group ppg on spp.soc = ppg.soc
  and ppg.pplan_series_type != 2
  -- pplan_series_type = 2 is non-revenue price plans, tests

left join (select rf.soc,rf.effective_date,rf.expiration_date,
  sum(case when rf.feature_code in ('UCCUSR','UCCENT') then 1 else 0 end) as MOBILE, --counts list of unique MOBILE feature_code identifiers
  sum(case when rf.feature_code in ('UC00XG','UC00XI','UC00XO') then 1 else 0 end) as OFFICE,--counts list of unique OFFICE feature_code identifiers
  sum(case when rf.feature_code like 'CPNR1%' or rf.feature_code like 'UCPNR1' then 1 else 0 end) as UCPNR1_CPNR1_one_time --counts list of unique MOBILE/OFFICE onetime charge feature_code identifiers
  from ods.rated_feature rf
  where rf.soc like 'UNI%'
  group by rf.soc,rf.effective_date,rf.expiration_date
  order by rf.soc,rf.effective_date) rf on sa.soc = rf.soc
    and rf.effective_date <= sa.effective_date 
    and (rf.expiration_date > sa.effective_date or rf.expiration_date is null)

/*check if the same SOC was added and removed from the BAN/CTN pair in the last 15 days using a different dealer code
then use the old dealer code and effective date in the select statement (will produce duplicates if the original sale date is around)*/
left join ods.service_agreement remove_check 
  
  on sa.ban = remove_check.ban
    and sa.subscriber_no = remove_check.subscriber_no
    and sa.soc = remove_check.soc
    and sa.effective_issue_date - remove_check.effective_issue_date < 15
    and sa.effective_issue_date > remove_check.effective_issue_date


join wl815963.employee_detail w2 on coalesce(remove_check.channel_id,sa.CHANNEL_ID) = w2.wireless_id
  and w2.effective_start_date <= sa.effective_date
  and (w2.effective_end_date >= sa.effective_date )
  and w2.channel IN ('Field Sales','Small - NIS','Lake Shore')
  
left join wl815963.employee_attribute w3 on coalesce(remove_check.channel_id,sa.CHANNEL_ID) = w3.wireless_id
  and w3.effective_start_date <= sa.effective_date
  and (w3.effective_end_date >= sa.effective_date )
  and w3.attribute_name = 'Employee Type' 

	
left join ods.billing_account ba on sa.ban = ba.ban

where sa.soc like 'UNI%'
and sa.channel_id not in ('TST99','OSRCP')
and sa.effective_issue_date >= to_date('2018-01-01','YYYY-MM-DD')
--And Exists (Select 1 From Wl815963.employee_detail w2
--	Where w2.wireless_id = sa.channel_id and (w2.channel IN ('Field Sales','Small - NIS','Lake Shore','Commercial - NIS')))
/*and exists (select 1
  from ods.subscriber sub where product_type in ('C','U') and  sa.ban = sub.customer_ban --this distinct join removes duplicate BAN,CTN pairs
  and sa.subscriber_no = sub.subscriber_no) */
  --need to also figure out why ALS_IND is different between C and U product_type for the same BAN, SUB pair
  )a where (pplan_series_type != 2 or pplan_series_type is null)
;