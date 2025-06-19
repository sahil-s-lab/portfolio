-------------------------------------------------------------------------------------
--Unison Query--
-------------------------------------------------------------------------------------

select * from(
select distinct w.employee_name,
w.manager_level_1,
case when sa.channel_id in ('35JAA', '1RF99','0MAAA','1RWAA') then 'NS Operations'
else w.channel end as channel,
coalesce(remove_check.channel_id,sa.CHANNEL_ID) channel_id,
w.employee_number as employee_id,
case when ba.last_business_name like '%|%' then null else  ba.last_business_name end as last_business_name, -- business name
sa.BAN,
sa.SUBSCRIBER_NO,
sa.soc,
ppg.pplan_series_type,
to_char(sa.effective_issue_date,'mm/dd/yyyy') as Report_date, --Effective_date,
--to_char(sa.expiration_issue_date,'mm/dd/yyyy') as Expiration_date, 
to_char(sa.effective_issue_date,'mm') as Report_Month, 
case when rf.MOBILE > 0 or rf.OFFICE > 0 then 
    case when (sa.expiration_issue_date - sa.effective_issue_date >= 15 or sa.expiration_issue_date is null) then 1
       else 0 end
  else 0 end as units, --checks whether the SOC has MOBILE/OFFICE "line" type features to count as a unit
case when (sa.expiration_issue_date - sa.effective_issue_date >= 15 or sa.expiration_issue_date is null) then 1 * pp.rate
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
 soc.soc_description as description,
'Activation' as sale_type,
case when sa.expiration_date is null then 1 else 0 end as Active,
null as Comm_Churn
  
from ODS.service_agreement sa
join ods.pp_rc_rate pp on sa.soc = pp.soc
    and pp.rate >= 1
    and pp.suspension_amount > 0
    and pp.effective_date <= sa.effective_date 
    and (pp.expiration_date > sa.effective_date or pp.expiration_date is null)
    
left join ods.cs_acct_segment seg on sa.ban = seg.ban and seg.crnt_ind = 'Y'
  left join ods.cs_segment csseg on seg.segment_skey = csseg.segment_skey

left join (select distinct subscriber_no,
  customer_ban
  from ods.subscriber where product_type in ('C','U')) sub on sa.ban = sub.customer_ban --this distinct join removes duplicate BAN,CTN pairs
  and sa.subscriber_no = sub.subscriber_no
  --need to also figure out why ALS_IND is different between C and U product_type for the same BAN, SUB pair
  
left join ods.subscriber_price_plan spp on sub.customer_ban = spp.ban --this join checks whether the price plan of the CTN is not a test
  and sub.subscriber_no = spp.subscriber_no
  and spp.effective_date <= sa.effective_date
  and (spp.expiration_date is null 
    or spp.expiration_date > sa.effective_date)
left join ods.price_plan_group ppg on spp.soc = ppg.soc
  --and ppg.pplan_series_type != 2
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

left join wl815963.employee_detail w on sa.channel_id = w.wireless_id
  and w.effective_start_date <= sa.effective_date
  and (w.effective_end_date >= sa.effective_date )
  --and w.employee_number is not null

/*check if the same SOC was added and removed from the BAN/CTN pair in the last 15 days using a different dealer code
then use the old dealer code and effective date in the select statement (will produce duplicates if the original sale date is around)*/
left join (select sa.ban,
  sa.subscriber_no,
  sa.soc,
  sa.channel_id,
  sa.effective_issue_date,
  row_number() over (partition by sa.ban, sa.subscriber_no, sa.soc order by sa.effective_issue_date desc) as row_num
  from ods.service_agreement sa
  where sa.soc like 'UNI%'
  order by sa.effective_issue_date) remove_check on sa.ban = remove_check.ban
    and sa.subscriber_no = remove_check.subscriber_no
    and sa.soc = remove_check.soc
    and sa.effective_issue_date - remove_check.effective_issue_date < 15
    and sa.effective_issue_date > remove_check.effective_issue_date
	
left join ods.soc soc on sa.soc = soc.soc
  and soc.effective_date <= sa.effective_issue_date
  and (soc.expiration_date > sa.effective_issue_date or soc.expiration_date is null)	

left join ods.billing_account ba on sa.ban = ba.ban

where sa.soc like 'UNI%'
and (sa.channel_id not in ('TST99','OSRCP') or sa.channel_id is null)
and sa.effective_issue_date >= to_date('2018-01-01','YYYY-MM-DD')


-------------------------------------------------------------------------------------
Union all    --Phase 2
-------------------------------------------------------------------------------------


select distinct w.employee_name,
w.manager_level_1,
case when sa.channel_id in ('35JAA', '1RF99','0MAAA','1RWAA') then 'NS Operations'
else w.channel
end as channel,
coalesce(remove_check.channel_id,sa.CHANNEL_ID) channel_id,
w.employee_number as employee_id,
case when ba.last_business_name like '%|%' then null else  ba.last_business_name end as last_business_name, -- business name
sa.BAN,
sa.SUBSCRIBER_NO,
sa.soc,
ppg.pplan_series_type,
to_char(sa.effective_issue_date,'mm/dd/yyyy') as Report_date, --Effective_date,
--to_char(sa.expiration_issue_date,'mm/dd/yyyy') as Expiration_date, 
to_char(sa.effective_issue_date,'mm') as Report_Month, 
case when rf.MOBILE > 0 or rf.OFFICE > 0 then 
    case when (sa.expiration_issue_date - sa.effective_issue_date >= 15 or sa.expiration_issue_date is null) then 1
           else 0 end
  else 0 end as units, --checks whether the SOC has MOBILE/OFFICE "line" type features to count as a unit
case when (sa.expiration_issue_date - sa.effective_issue_date >= 15 or sa.expiration_issue_date is null) then 1 * pp.rate
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
soc.soc_description as description,
'Activation' as sale_type,
case when sa.expiration_date is null then 1 else 0 end as Active,
null as Comm_Churn
  
from ODS.subscriber_price_plan sa
join ods.pp_rc_rate pp on sa.soc = pp.soc
    and pp.rate >= 1
    and pp.suspension_amount > 0
    and pp.effective_date <= sa.effective_date 
    and (pp.expiration_date > sa.effective_date or pp.expiration_date is null)
    
left join ods.cs_acct_segment seg on sa.ban = seg.ban and seg.crnt_ind = 'Y'
  left join ods.cs_segment csseg on seg.segment_skey = csseg.segment_skey

left join (select distinct subscriber_no,
  customer_ban
  from ods.subscriber where product_type in ('C','U')) sub on sa.ban = sub.customer_ban --this distinct join removes duplicate BAN,CTN pairs
  and sa.subscriber_no = sub.subscriber_no
  --need to also figure out why ALS_IND is different between C and U product_type for the same BAN, SUB pair
  
left join ods.subscriber_price_plan spp on sub.customer_ban = spp.ban --this join checks whether the price plan of the CTN is not a test
  and sub.subscriber_no = spp.subscriber_no
  and spp.effective_date <= sa.effective_date
  and (spp.expiration_date is null 
    or spp.expiration_date > sa.effective_date)
left join ods.price_plan_group ppg on spp.soc = ppg.soc
  --and ppg.pplan_series_type != 2
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

left join wl815963.employee_detail w on sa.channel_id = w.wireless_id
  and w.effective_start_date <= sa.effective_date
  and (/*w.EFFECTIVE_END_DATE is null or*/ w.effective_end_date >= sa.effective_date )
  --and w.employee_number is not null

/*check if the same SOC was added and removed from the BAN/CTN pair in the last 15 days using a different dealer code
then use the old dealer code and effective date in the select statement (will produce duplicates if the original sale date is around)*/
left join (select sa.ban,
  sa.subscriber_no,
  sa.soc,
  sa.channel_id,
  sa.effective_issue_date,
  row_number() over (partition by sa.ban, sa.subscriber_no, sa.soc order by sa.effective_issue_date desc) as row_num
  from ods.service_agreement sa
  where sa.soc like 'UNI%'
  order by sa.effective_issue_date) remove_check on sa.ban = remove_check.ban
    and sa.subscriber_no = remove_check.subscriber_no
    and sa.soc = remove_check.soc
    and sa.effective_issue_date - remove_check.effective_issue_date < 15
    and sa.effective_issue_date > remove_check.effective_issue_date

left join ods.billing_account ba on sa.ban = ba.ban

left join ods.soc soc on sa.soc = soc.soc
  and soc.effective_date <= sa.effective_issue_date
  and (soc.expiration_date > sa.effective_issue_date or soc.expiration_date is null)

where sa.soc like 'UNI%'
and (sa.channel_id not in ('TST99','OSRCP') or sa.channel_id is null)
and sa.effective_issue_date >= to_date('2018-01-01','YYYY-MM-DD')




--And Exists (Select 1 From Wl815963.employee Wl Where Wl.Wireless_Id = sA.channel_id and (wl.channel IN ('Field Sales','Small - NIS','Lake Shore')))
-------------------------------------------------------------------------------------
Union all      --Phase 1 Churn
-------------------------------------------------------------------------------------



select distinct w.employee_name,
w.manager_level_1,
case when sa.channel_id in ('35JAA', '1RF99','0MAAA','1RWAA') then 'NS Operations'
else w.channel
end as channel,
coalesce(remove_check.channel_id,sa.CHANNEL_ID) channel_id,
w.employee_number as employee_id,
case when ba.last_business_name like '%|%' then null else  ba.last_business_name end as last_business_name, -- business name
sa.BAN,
sa.SUBSCRIBER_NO,
sa.soc,
ppg.pplan_series_type,
--to_char(sa.effective_issue_date,'mm/dd/yyyy') as Effective_date, -- change to churn date
to_char(sa.expiration_issue_date,'mm/dd/yyyy') as Report_Date,                    --Expiration_date, -- change to churn date
to_char(sa.expiration_issue_date,'mm') as Report_Month, 
case when rf.MOBILE > 0 or rf.OFFICE > 0 then 
    case when (sa.expiration_issue_date - sa.effective_issue_date >= 15) then -1 --removed expiration date is null
--when (sa.expiration_issue_date - sa.effective_issue_date < 15 
          --and to_char(sa.effective_issue_date,'mm') !=  to_char(sa.expiration_issue_date,'mm')) then -1
      else 0 end
  else 0 end as units, --checks whether the SOC has MOBILE/OFFICE "line" type features to count as a unit
case when rf.UCPNR1_CPNR1_one_time > 0 then 0
when (sa.expiration_issue_date - sa.effective_issue_date >= 15)  then -1 * pp.rate--removed expiration date is null
 -- when  (sa.expiration_issue_date - sa.effective_issue_date < 15 and
   -- to_char(sa.effective_issue_date,'mm') !=  to_char(sa.expiration_issue_date,'mm')) then -1 * pp.rate
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
soc.soc_description as description,
'Churn' as activity_type,
0 as Active,
case when sa.expiration_issue_date - sa.effective_issue_date <= 90 then 'Less than 90 Day Churn'
 else 'Over 90 Day Churn' end as Comm_Churn
  
from ODS.service_agreement sa
join ods.pp_rc_rate pp on sa.soc = pp.soc
    and pp.rate >= 1
    and pp.suspension_amount > 0
    and pp.effective_date <= sa.effective_date 
    and (pp.expiration_date > sa.effective_date or pp.expiration_date is null)
    
left join ods.cs_acct_segment seg on sa.ban = seg.ban and seg.crnt_ind = 'Y'
  left join ods.cs_segment csseg on seg.segment_skey = csseg.segment_skey

left join (select distinct subscriber_no,
  customer_ban
  from ods.subscriber where product_type in ('C','U')) sub on sa.ban = sub.customer_ban --this distinct join removes duplicate BAN,CTN pairs
  and sa.subscriber_no = sub.subscriber_no
  --need to also figure out why ALS_IND is different between C and U product_type for the same BAN, SUB pair
  
left join ods.subscriber_price_plan spp on sub.customer_ban = spp.ban --this join checks whether the price plan of the CTN is not a test
  and sub.subscriber_no = spp.subscriber_no
  and spp.effective_date <= sa.effective_date
  and (spp.expiration_date is null 
    or spp.expiration_date > sa.effective_date)
left join ods.price_plan_group ppg on spp.soc = ppg.soc
  --and ppg.pplan_series_type != 2
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
left join (select sa.ban,
  sa.subscriber_no,
  sa.soc,
  sa.channel_id,
  sa.effective_issue_date,
  sa.expiration_issue_date, --added expiration date
  row_number() over (partition by sa.ban, sa.subscriber_no, sa.soc order by sa.effective_issue_date desc) as row_num
  from ods.service_agreement sa
  where sa.soc like 'UNI%'
  order by sa.effective_issue_date) remove_check on sa.ban = remove_check.ban
    and sa.subscriber_no = remove_check.subscriber_no
    and sa.soc = remove_check.soc
    and sa.effective_issue_date - remove_check.effective_issue_date < 15
    and sa.effective_issue_date > remove_check.effective_issue_date

left join wl815963.employee_detail w on coalesce(remove_check.channel_id,sa.CHANNEL_ID) = w.wireless_id
  and w.effective_start_date <= sa.expiration_date
  and (/*w.EFFECTIVE_END_DATE is null or*/ w.effective_end_date >= sa.expiration_date )

	
left join ods.billing_account ba on sa.ban = ba.ban

left join ods.soc soc on sa.soc = soc.soc
  and soc.effective_date <= sa.effective_issue_date
  and (soc.expiration_date > sa.effective_issue_date or soc.expiration_date is null)

where sa.soc like 'UNI%'
and (sa.channel_id not in ('TST99','OSRCP') or sa.channel_id is null)
--and sa.effective_issue_date >= to_date('2017-01-01','YYYY-MM-DD') 
and sa.expiration_issue_date >= to_date('2018-1-01','YYYY-MM-DD') --changed to expiration date
and (sa.expiration_issue_date - sa.effective_issue_date >= 15)
--or (sa.expiration_issue_date - sa.effective_issue_date < 15 and
--    to_char(sa.effective_issue_date,'mm') !=  to_char(sa.expiration_issue_date,'mm')))--added to only look at post 15 day churn
--and sa.expiration_issue_date - sa.effective_issue_date <= 90 -- 90 day comm churn rule
--And Exists (Select 1 From Wl815963.employee Wl Where Wl.Wireless_Id = sa.Channel_Id and (wl.channel IN ('Field Sales','Small - NIS','Lake Shore')))

-------------------------------------------------------------------------------------
Union all      --Phase 2 Churn
-------------------------------------------------------------------------------------


select distinct w.employee_name,
w.manager_level_1,
case when sa.channel_id in ('35JAA', '1RF99','0MAAA','1RWAA') then 'NS Operations'
else w.channel
end as channel,
coalesce(remove_check.channel_id,sa.CHANNEL_ID) channel_id,
w.employee_number as employee_id,
case when ba.last_business_name like '%|%' then null else  ba.last_business_name end as last_business_name, -- business name
sa.BAN,
sa.SUBSCRIBER_NO,
sa.soc,
ppg.pplan_series_type,
to_char(sa.expiration_issue_date,'mm/dd/yyyy') as report_date, -- change to churn date
to_char(sa.expiration_issue_date,'mm') as report_month,
case when rf.MOBILE > 0 or rf.OFFICE > 0 then 
    case when (sa.expiration_issue_date - sa.effective_issue_date >= 15) then -1 --removed expiration date is null
        when (sa.expiration_issue_date - sa.effective_issue_date < 15 
          and to_char(sa.effective_issue_date,'mm') !=  to_char(sa.expiration_issue_date,'mm')) then -1
      else 0 end
  else 0 end as units, --checks whether the SOC has MOBILE/OFFICE "line" type features to count as a unit
case when rf.UCPNR1_CPNR1_one_time > 0 then 0
when (sa.expiration_issue_date - sa.effective_issue_date >= 15) then -1 * pp.rate  --removed expiration date is null
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
soc.soc_description as description,
'Churn' as activity_type,
0 as Active,
case when sa.expiration_issue_date - sa.effective_issue_date <= 90 then 'Less than 90 Day Churn'
 else 'Over 90 Day Churn' end as Comm_Churn
 
from ODS.subscriber_price_plan sa
join ods.pp_rc_rate pp on sa.soc = pp.soc
    and pp.rate >= 1
    and pp.suspension_amount > 0
    and pp.effective_date <= sa.effective_date 
    and (pp.expiration_date > sa.effective_date or pp.expiration_date is null)
    
left join ods.cs_acct_segment seg on sa.ban = seg.ban and seg.crnt_ind = 'Y'
  left join ods.cs_segment csseg on seg.segment_skey = csseg.segment_skey

left join (select distinct subscriber_no,
  customer_ban
  from ods.subscriber where product_type in ('C','U')) sub on sa.ban = sub.customer_ban --this distinct join removes duplicate BAN,CTN pairs
  and sa.subscriber_no = sub.subscriber_no
  --need to also figure out why ALS_IND is different between C and U product_type for the same BAN, SUB pair
  
left join ods.subscriber_price_plan spp on sub.customer_ban = spp.ban --this join checks whether the price plan of the CTN is not a test
  and sub.subscriber_no = spp.subscriber_no
  and spp.effective_date <= sa.effective_date
  and (spp.expiration_date is null 
    or spp.expiration_date > sa.effective_date)
left join ods.price_plan_group ppg on spp.soc = ppg.soc
  --and ppg.pplan_series_type != 2
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
left join (select sa.ban,
  sa.subscriber_no,
  sa.soc,
  sa.channel_id,
  sa.effective_issue_date,
  sa.expiration_issue_date, --added expiration date
  row_number() over (partition by sa.ban, sa.subscriber_no, sa.soc order by sa.effective_issue_date desc) as row_num
  from ods.service_agreement sa
  where sa.soc like 'UNI%'
  order by sa.effective_issue_date) remove_check on sa.ban = remove_check.ban
    and sa.subscriber_no = remove_check.subscriber_no
    and sa.soc = remove_check.soc
    and sa.effective_issue_date - remove_check.effective_issue_date < 15
    and sa.effective_issue_date > remove_check.effective_issue_date

left join wl815963.employee_detail w on coalesce(remove_check.channel_id,sa.CHANNEL_ID) = w.wireless_id
  and w.effective_start_date <= sa.expiration_date
  and (/*w.EFFECTIVE_END_DATE is null or*/ w.effective_end_date >= sa.expiration_date )

	
left join ods.billing_account ba on sa.ban = ba.ban

left join ods.soc soc on sa.soc = soc.soc
  and soc.effective_date <= sa.effective_issue_date
  and (soc.expiration_date > sa.effective_issue_date or soc.expiration_date is null)

where sa.soc like 'UNI%'
and (sa.channel_id not in ('TST99','OSRCP') or sa.channel_id is null)
--and sa.effective_issue_date >= to_date('2017-01-01','YYYY-MM-DD') 
and sa.expiration_issue_date >= to_date('2018-01-01','YYYY-MM-DD') --changed to expiration date
and sa.expiration_issue_date - sa.effective_issue_date >= 15 
--or (sa.expiration_issue_date - sa.effective_issue_date < 15 and
 --   to_char(sa.effective_issue_date,'mm') !=  to_char(sa.expiration_issue_date,'mm')))--added to only look at post 15 day churn
--and sa.expiration_issue_date - sa.effective_issue_date <= 90 -- 90 day comm churn rule
--And Exists (Select 1 From Wl815963.employee Wl Where Wl.Wireless_Id = sa.Channel_Id and (wl.channel IN ('Field Sales','Small - NIS','Lake Shore')))

order by 11 desc, 18  desc
)  a where pplan_series_type != 2 or pplan_series_type is null
;