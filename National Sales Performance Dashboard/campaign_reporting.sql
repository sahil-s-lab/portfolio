/* UPDATE NOTES
 - Add filter for "Data Source" field on campaign object
 - For Commercial facing campaigns, want to show Opportunities in funnel from innactive campaigns
 
*/

WITH campaigns AS	-- SET TARGETED CAMPAIGNS
(
	SELECT
	c.id campaignid,
	c.Campaign_Tactic__c,
	c.name campaign_name,
	c.owner_name campaign_owner,
	c.startdate,
	c.enddate,
	c.channel__c,
	c.Online_submission_flow__c,
	ownerid,
	owner_name,
	campaign_originator__c

	FROM ebu.campaign c

	WHERE c.startdate <= CURRENT_DATE
	AND c.enddate >= CURRENT_DATE
	AND
	(
		c.owner_name = 'Colin Marsh'
		OR c.owner_name = 'Shay Sheldrick'
		OR (c.owner_name = 'Saad Afsar' AND c.campaign_tactic__c LIKE 'CiaB Q%' AND c.type = 'Phone Call')
		OR c.owner_name = 'Rozenn Martin'
		OR c.owner_name = 'Nasim Soltanpour'
	)
),

leads AS		-- CAPTURE ALL CAMPAIGN MEMBERS ASSIGNED TO SMALL OR COMMERCIAL SALES
(
	SELECT
	m.id memberid,
	m.campaignid,
	m.leadid,
	m.contactid,
	m.status,
	m.call_touches__c,
	m.assigned_to__c,
	m.assigned_to_full_name__c,
	m.assigned_to_manager__c,
	m.assigned_to_director__c,
	m.assigned_to_channel__c,
	m.member_first_associated_date__c

	FROM ebu.campaign_member m

	JOIN campaigns c ON c.campaignid = m.campaignid

	WHERE m.assigned_to_channel__c IN ('Small')
),

r AS		-- earliest RPC tasks related to active campaign
(
        SELECT
            cm.id campaign_member_id,
            MIN(cm.Member_First_Associated_Date__c) Member_First_Associated_Date__c,
            MIN(cm.assigned_to__c) assigned_to__c,
            MIN(COALESCE(cm.contactid, cm.leadid)) member_id,
            MIN(t.createddate) task_created_date
        FROM
            ebu.campaign_member cm
        JOIN ebu.campaign c
        ON
            c.id = cm.campaignid
        AND c.startdate <= CURRENT_DATE
        AND c.enddate >= CURRENT_DATE
        AND c.type = 'Phone Call'
        AND c.channel__c = 'Small'
        AND c.campaign_originator__c = 'Marketing'
        JOIN ebu.task t
        ON
            t.whoid = COALESCE(cm.contactid, cm.leadid)
        AND t.ownerid = cm.assigned_to__c
        AND t.createddate >= cm.Member_First_Associated_Date__c
        AND
            (
                t.subject_type__c LIKE '%RPC%'
             OR t.calldisposition = 'Correct Contact'
            )
        GROUP BY
            1
),

rpc AS
(
	SELECT
	    r.campaign_member_id,
	    COUNT(1) first_rpc
	FROM
	    r
	JOIN ebu.task t
	ON
	    t.ownerid = r.assigned_to__c
	AND t.createddate <= r.task_created_date
	AND t.createddate >= r.member_first_associated_date__c
	AND r.member_id = t.whoid
	GROUP BY
	    1

),

opps AS		-- CAPTURE ALL RELATED OPPORTUNITIES
(
	SELECT
	o.id opportunityid,
	oc.contactid,
	o.accountid,
	o.campaignid,
	o.ownerid,
	o.owner_name,
	o.opportunity_owner_manager__c,
	o.owner_director__c,
	o.record_type,
	o.stagename,
	o.closedate::DATE,
	(
	   COALESCE(o.EBU_Revenue__c,0.0) +
	   COALESCE(MRR_IoT_Applications_Expected__c,0.0) +
	   COALESCE(MRR_Data_Centre_Cloud_Expected__c,0.0) +
	   COALESCE(MRR_Wireless_Expected__c,0.0) +
	   COALESCE(MRR_Wireline_Fixed_Access_Expected__c,0.0) +
	   COALESCE(MRR_Security_Expected__c,0.0)
	)  as opp_mrr,
	(
	   COALESCE(CASE WHEN o.product_category__c LIKE 'Wireless%' THEN o.ebu_revenue__c ELSE 0 END,0) +
	   COALESCE(MRR_Wireless_Expected__c,0.0)
	)  as opp_wireless_mrr,
	(
	   COALESCE(CASE WHEN o.product_category__c LIKE 'Wireline%' THEN o.ebu_revenue__c ELSE 0 END,0) +
	   COALESCE(MRR_Wireline_Fixed_Access_Expected__c,0.0)
	)  as opp_wireline_mrr

	FROM ebu.opportunity o

	JOIN campaigns ca ON ca.campaignid = o.campaignid
	LEFT JOIN ebu.opportunity_contact_role oc ON oc.opportunityid = o.id
	LEFT JOIN ebu.contact c ON c.id = oc.contactid
),

stage_history AS -- CALCULATE TIME SPENT IN CURRENT OPPORTUNITY STAGE
(
	SELECT DISTINCT ON (h.opportunityid)
	h.opportunityid,
	h.oldvalue,
	h.newvalue,
	h.createdbyid,
	h.createddate,
	DATE_PART('day',CURRENT_DATE - h.createddate) AS stage_duration

	FROM ebu.opportunity_field_history h

	JOIN opps o ON o.opportunityid = h.opportunityid
	
	WHERE h.field = 'StageName'
	ORDER BY h.opportunityid,h.createddate DESC
),

lead_pivot AS	-- PIVOT LEAD DATA FOR TOTALS AND DISPOSITION
(
	SELECT
	c.campaign_name,
	c.Campaign_Tactic__c,
	c.campaign_owner,
	c.channel__c,
	c.Online_submission_flow__c,
	CASE 
	 WHEN (l.assigned_to_director__c = 'Steve Furman' OR l.assigned_to_manager__c = 'Steve Furman') THEN 'NOS'
	 WHEN (l.assigned_to_director__c = 'Jason Giff' OR l.assigned_to_manager__c = 'Jason Giff') THEN 'Field'
	 ELSE l.assigned_to_director__c
	END as assigned_to_channel,
	ROUND(AVG(CASE WHEN l.call_touches__c > 0 THEN l.call_touches__c::NUMERIC ELSE NULL END),2) avg_attempts,

	COUNT(l.memberid) total_leads,
	COUNT(CASE WHEN l.status NOT IN ('New','Reserve') THEN l.memberid ELSE NULL END) dispositioned_leads,
	COUNT(r.campaign_member_id) contacted_leads,
	ROUND(AVG(r.first_rpc),2) avg_first_rpc

	FROM campaigns c

	LEFT JOIN leads l ON l.campaignid = c.campaignid
	LEFT JOIN rpc r ON r.campaign_member_id = l.memberid

	GROUP BY 1,2,3,4,5,6
),

opp_pivot AS	-- PIVOT OPP DATA FOR TOTALS, STAGES AND MRR
(
	SELECT
	c.campaign_name,
	Campaign_Tactic__c,
	c.campaign_owner,
	c.channel__c,
	c.Online_submission_flow__c,
	CASE 
	 WHEN (o.owner_director__c = 'Steve Furman' OR o.opportunity_owner_manager__c = 'Steve Furman') THEN 'NOS'
	 WHEN (o.owner_director__c = 'Jason Giff' OR o.opportunity_owner_manager__c = 'Jason Giff') THEN 'Field'
	 ELSE o.owner_director__c
	END as opp_channel,

	COUNT(o.opportunityid) total_opps,
	COUNT(CASE WHEN o.stagename IN ('Suspect','Identify','Qualify') THEN o.opportunityid ELSE NULL END) early_opps,
	SUM(CASE WHEN o.stagename IN ('Suspect','Identify','Qualify') THEN o.opp_mrr ELSE 0 END) early_mrr,
	COUNT(CASE WHEN o.stagename IN ('Propose','Negotiate','Commit') THEN o.opportunityid ELSE NULL END) middle_opps,
	SUM(CASE WHEN o.stagename IN ('Propose','Negotiate','Commit') THEN o.opp_mrr ELSE 0 END) middle_mrr,
	COUNT(CASE WHEN o.stagename IN ('Closed Lost') THEN o.opportunityid ELSE NULL END) lost_opps,
	SUM(CASE WHEN o.stagename IN ('Closed Lost') THEN o.opp_mrr ELSE 0 END) lost_mrr,
	COUNT(CASE WHEN o.stagename IN ('Closed Won') THEN o.opportunityid ELSE NULL END) won_opps,
	SUM(CASE WHEN o.stagename IN ('Closed Won') THEN o.opp_mrr ELSE 0 END) won_mrr,
	SUM(CASE WHEN o.stagename IN ('Closed Won') THEN o.opp_wireless_mrr ELSE 0 END) won_wireless_mrr,	
	SUM(CASE WHEN o.stagename IN ('Closed Won') THEN o.opp_wireline_mrr ELSE 0 END) won_wireline_mrr
		
	FROM campaigns c

	LEFT JOIN opps o ON o.campaignid = c.campaignid

	GROUP BY 1,2,3,4,5,6
)
-- DATA OUTPUT QUERY
SELECT
c.campaign_name,
c.Campaign_Tactic__c,
c.campaign_owner,
c.channel__c,
c.Online_submission_flow__c,
l.assigned_to_channel,
o.opp_channel,

l.avg_attempts,
l.avg_first_rpc,
l.total_leads,
l.dispositioned_leads,
l.contacted_leads,

o.total_opps,
o.early_opps,
o.early_mrr,
o.middle_opps,
o.middle_mrr,
o.lost_opps,
o.lost_mrr,
o.won_opps,
o.won_mrr::NUMERIC,
o.won_wireless_mrr::NUMERIC,
o.won_wireline_mrr::NUMERIC

FROM campaigns c

LEFT JOIN lead_pivot l ON l.campaign_name = c.campaign_name
LEFT JOIN opp_pivot o ON o.campaign_name = c.campaign_name 
  AND 
  (
     l.assigned_to_channel = o.opp_channel 
     OR l.total_leads = 0
     OR (l.assigned_to_channel IS NULL AND o.opp_channel IS NULL)
     )

--WHERE l.total_leads > 0

