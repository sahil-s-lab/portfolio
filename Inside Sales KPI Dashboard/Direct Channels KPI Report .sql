-------------------------
--SMALL NIS +LAKE SHORE 
-------------------------
select ed.channel__c, Date(t.activitydate), ed.manager_level_1__c,	
e.employee_name__c,	u.employee_id__c,


sum(case when t.subject_type__c != 'Email' then 1 else 0 end) as total_calls,
sum(case when t.subject_type__c = 'Base call' then 1 else 0 end) as base_calls,	
sum(case when t.subject_type__c = 'Base Call - RPC' then 1 else 0 end) as base_calls_rpc,	
sum(case when t.subject_type__c = 'Prospecting call' then 1 else 0 end) as prospect_calls,	
sum(case when t.subject_type__c = 'Prospecting Call - RPC' then 1 else 0 end) as prospect_calls_rpc,	
sum(case when t.subject_type__c = 'Follow up call' then 1 else 0 end) as follow_up_call,	
sum(case when t.subject_type__c = 'Proposal' then 1 else 0 end) as proposal,	
sum(case when t.subject_type__c = 'Email' then 1 else 0 end) as emails,
null as new_opps

from vicinity.employee e
	

join vicinity.employee_detail ed on e.id = ed.employee__c	
	and ed.channel__c in ('Lake Shore', 'Small - NIS', 'Field Sales')
	and ed.effective_end_date__c is null 

join ebu.user u on e.employee_number__c = u.employee_id__c	
	and u.isactive = true

left join ebu.task t on u.id = t.ownerid	
	and t.isclosed = true
	and t.isdeleted = false

where t.activitydate between '2018-01-01' and '2018-01-31'
	and not e.employee_name__c = 'Charlynne Pinto'

group by 1, 2, 3, 4, 5

---------------------
UNION ALL 
--New Opportunities  (queue second)
---------------------
select ed.channel__c, Date(o.createddate), ed.manager_level_1__c,	
e.employee_name__c,	u.employee_id__c,


null as total_calls,	
null as base_calls,	
null as base_calls_rpc,	
null as prospect_calls,	
null as prospect_calls_rpc,	
null as follow_up_call,	
null as proposal,	
null as emails,
count(o.id) as new_opps


from vicinity.employee e
	

join vicinity.employee_detail ed on e.id = ed.employee__c	
	and ed.channel__c in ('Lake Shore', 'Small - NIS', 'Field Sales')
	and ed.effective_end_date__c is null 

join ebu.user u on e.employee_number__c = u.employee_id__c	
	and u.isactive = true

join ebu.opportunity o on u.id = o.createdbyid 

where o.createddate between '2018-01-01' and '2018-01-31'
	and not e.employee_name__c = 'Charlynne Pinto'

group by 1, 2, 3, 4, 5 
order by 1, 2 desc, 5 desc, 3, 4

