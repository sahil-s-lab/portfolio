select w2.employee_name,
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
null as units, -- no unit value
case when a.activation > 0 or a.resume_non_churn > 0 then 
	case when pp.rate > 0 then pp.rate
		when a.pplan_series_type = 5 then pp2.rate end
	when  a.last_act = 'CA' and s.deactivation_date is not null then
		case when pp.rate > 0 then -pp.rate
			when a.pplan_series_type = 5 then -pp2.rate end
	else 0 end as rate,
case when a.pplan_group_cd in ('WHPS','WHPC') then 'WBP'
  when a.pplan_series_type = 5 then 'MBB'
  else 'VOICE' end as Type,
csseg.segment_desc,
soc.soc_description as description,
case when a.activation > 0 or a.resume_non_churn > 0 then 'Activation' else 'Churn' end as activity_type,
w3.attribute_value

from ods.msp_activity_hist a
/* Add segment data*/
left join ods.cs_acct_segment seg on a.BAN = seg.ban and seg.crnt_ind = 'Y'
  left join ods.cs_segment csseg on seg.segment_skey = csseg.segment_skey

join ods.service_agreement sa on a.subscriber_no = sa.subscriber_no
  and a.ban = sa.ban
  and a.init_activation_date = sa.effective_date
  and a.sub_channel_id = sa.channel_id
  and (sa.expiration_date is null or sa.expiration_date > sa.effective_date)
  
left join ods.pp_rc_rate pp on sa.soc = pp.soc
	and (/*a.pplan_series_type = 1 and*/ pp.rate >=1 and pp.suspension_amount > 0)
  and pp.effective_date <= sa.effective_date 
  and (pp.expiration_date > sa.effective_date or pp.expiration_date is null)

left join ods.pp_rc_rate pp2 on sa.soc = pp2.soc
  and (/*a.pplan_series_type = 5 and*/ pp2.rate >=1 and pp2.tier_level_code = 1)
  and pp2.effective_date <= sa.effective_date 
  and (pp2.expiration_date > sa.effective_date or pp2.expiration_date is null)
  
left join ods.billing_account BA on a.ban = ba.ban
left join ods.subscriber s on a.subscriber_no = s.subscriber_no
  and a.ban = s.customer_ban

left join wl815963.employee_detail w2 on sa.channel_id = w2.wireless_id
  and w2.effective_start_date <= case when a.activation > 0 or a.resume_non_churn > 0 then sa.effective_date else sa.expiration_date end
  and ( w2.effective_end_date >= case when a.activation > 0 or a.resume_non_churn > 0 then sa.effective_date else sa.expiration_date end)

  
 left join wl815963.employee_attribute w3 on sa.channel_id = w3.wireless_id
  and w3.effective_start_date <= sa.effective_date
  and ( w3.effective_end_date >= sa.effective_date )
  and w3.attribute_name = 'Employee Type' 

left join ods.soc soc on sa.soc = soc.soc
  and soc.effective_date <= sa.effective_date
  and (soc.expiration_date > sa.effective_date or soc.expiration_date is null)

where a.msp_year in 2018
and a.msp_month in (1)
and lower(soc.soc_description) not like '%applecare%' 

AND (a.activation > 0 
	or (a.last_act = 'CA' and  a.deactivation_date - a.init_activation_date <= 90)
	or (a.last_act = 'RC' and a.resume_non_churn > 0))
and sa.soc not like 'UNI%'
and (pp.rate > 0 or (a.pplan_series_type = 5 and pp2.rate > 0))
And Exists (Select 1 From Wl815963.employee_detail w2
	Where w2.wireless_id = a.sub_channel_id and (w2.channel IN ('Field Sales','Small - NIS','Lake Shore')))
;