-------------------------------------
--TSR Assigned Web Form Postal Codes
-------------------------------------
WITH field_territory_assignments AS 
(
	SELECT 
		DATE(ta.assigned_date__c),
		ed.channel__c, 
		ed.manager_level_1__c,	
		u.id AS userid,
		e.wireless_id__c,
		e.employee_name__c AS territory_owner,
		u.employee_id__c,
		UPPER(LEFT(ta.postal_code__c,3)||RIGHT(ta.postal_code__c,3)) AS postal_code__c

	FROM ebu.territory_assignment ta
		JOIN ebu.user u ON u.id = ta.assigned_to__c
			--AND u.isactive = TRUE
		LEFT JOIN vicinity.employee e ON e.employee_number__c  = u.employee_id__c
		LEFT JOIN vicinity.employee_detail ed ON ed.employee__c = e.id
			AND ed.channel__c IN ('Field Sales')
			AND ed.effective_start_date__c  <= ta.assigned_date__c 
			AND (ed.effective_end_date__c IS NULL  OR ed.effective_end_date__c >= ta.assigned_date__c)
),

--tasks which inckude postal codes from the lead/contact/account/opportunity object 
tasks AS
(
    SELECT
		t.id taskid,
		t.ownerid,
		t.status,
		t.subject_type__c,
		DATE(t.activitydate),
		UPPER(LEFT(ac.billingpostalcode,3)||RIGHT(ac.billingpostalcode,3)) AS postalcode

	FROM vicinity.employee e
		JOIN vicinity.employee_detail ed ON e.id = ed.employee__c	
			AND ed.channel__c IN ('Field Sales')
			AND ed.effective_end_date__c IS NULL 
		JOIN ebu.user u ON e.employee_number__c = u.employee_id__c	
			AND u.isactive = TRUE
		LEFT JOIN ebu.task t ON u.id = t.ownerid	
			AND t.activitydate BETWEEN '2019-01-01' AND CURRENT_DATE - 1
			AND t.isclosed = TRUE
			AND t.isdeleted = FALSE		
		JOIN ebu.account ac ON ac.id = COALESCE(t.accountid, t.whatid)
	

UNION ALL 

    SELECT
		t.id taskid,
		t.ownerid,
		t.status,
		t.subject_type__c,
		DATE(t.activitydate),
		UPPER(LEFT(c.mailingpostalcode,3)||RIGHT(c.mailingpostalcode,3))

	FROM vicinity.employee e
		JOIN vicinity.employee_detail ed ON e.id = ed.employee__c	
			AND ed.channel__c IN ('Field Sales')
			AND ed.effective_end_date__c IS NULL 
		JOIN ebu.user u ON e.employee_number__c = u.employee_id__c	
			AND u.isactive = TRUE
		LEFT JOIN ebu.task t ON u.id = t.ownerid	
			AND t.activitydate BETWEEN '2019-01-01' AND CURRENT_DATE - 1
			AND t.isclosed = TRUE
			AND t.isdeleted = FALSE		
		JOIN ebu.contact c ON c.id = t.whoid 
		

UNION ALL 

    SELECT
		t.id taskid,
		t.ownerid,
		t.status,
		t.subject_type__c,
		DATE(t.activitydate),
		UPPER(LEFT(l.postalcode,3)||RIGHT(l.postalcode,3)) 

	FROM vicinity.employee e
		JOIN vicinity.employee_detail ed ON e.id = ed.employee__c	
			AND ed.channel__c IN ('Field Sales')
			AND ed.effective_end_date__c IS NULL 
		JOIN ebu.user u ON e.employee_number__c = u.employee_id__c	
			AND u.isactive = TRUE
		LEFT JOIN ebu.task t ON u.id = t.ownerid	
			AND t.activitydate BETWEEN '2019-01-01' AND CURRENT_DATE - 1
			AND t.isclosed = TRUE
			AND t.isdeleted = FALSE	
		JOIN ebu.lead l ON l.id = t.whoid
),

--include tasks that are not created on another object and determine if activity created within assigned territory 
task_in_TSR AS 
(
    SELECT
		ed.channel__c, 
		ed.manager_level_1__c,	
		e.employee_name__c,
		t.id,
		t.ownerid,
		t.status,
		t.subject_type__c,
		DATE(t.activitydate) AS activitydate,
	CASE 
		WHEN (t.ownerid != a.userid AND a.userid != '005i00000091qwfAAA') THEN 'Foreign Territory'
		WHEN t.ownerid = a.userid THEN 'In Territory' 
		WHEN a.userid = '005i00000091qwfAAA' THEN 'Outside Territory'
		WHEN a.userid IS NULL THEN 'No Postal Code'
	END AS correct_assigned_TSR
	
	FROM vicinity.employee e
		JOIN vicinity.employee_detail ed ON e.id = ed.employee__c	
			AND ed.channel__c IN ('Field Sales')
			AND ed.effective_end_date__c IS NULL 
		JOIN ebu.user u ON e.employee_number__c = u.employee_id__c	
			AND u.isactive = TRUE
		LEFT JOIN ebu.task t ON u.id = t.ownerid	
			AND t.isclosed = TRUE
			AND t.isdeleted = FALSE	
		LEFT JOIN tasks ta ON ta.taskid = t.id
		LEFT JOIN field_territory_assignments a on a.postal_code__c = ta.postalcode
			
	WHERE t.activitydate BETWEEN '2019-01-01' AND CURRENT_DATE - 1
			AND t.subject_type__c IS NOT NULL
)


-----------------------------------------
--Field Sales Activities 
-----------------------------------------
SELECT 
	t.channel__c, 
	t.activitydate,
	t.manager_level_1__c,	
	t.employee_name__c,	
	t.correct_assigned_TSR,
	SUM(CASE WHEN t.subject_type__c IS NOT NULL THEN 1 ELSE 0 END) AS total_activities,	
	SUM(CASE WHEN t.subject_type__c = 'Door Knock RPC' THEN 1 ELSE 0 END) AS door_knock_RPC,	
	SUM(CASE WHEN t.subject_type__c = 'Account Review' THEN 1 ELSE 0 END) AS account_review,	
	SUM(CASE WHEN t.subject_type__c = 'Follow up call' THEN 1 ELSE 0 END) AS follow_up_call,	
	SUM(CASE WHEN t.subject_type__c = 'Face to Face Meeting' THEN 1 ELSE 0 END) AS face_to_face_meeting,	
	SUM(CASE WHEN t.subject_type__c = 'Base Call - RPC' THEN 1 ELSE 0 END) AS base_call_RPC,	
	SUM(CASE WHEN t.subject_type__c = 'Prospecting Call - RPC' THEN 1 ELSE 0 END) AS prospecting_call_RPC,	
	SUM(CASE WHEN t.subject_type__c = 'Base call' THEN 1 ELSE 0 END) AS base_call,	
	SUM(CASE WHEN t.subject_type__c = 'Prospecting call' THEN 1 ELSE 0 END) AS prospecting_call,	
	SUM(CASE WHEN t.subject_type__c = 'Email' THEN 1 ELSE 0 END) AS email,
	NULL AS new_opps

FROM task_in_TSR AS t	
		
WHERE t.activitydate BETWEEN '2019-01-01' AND CURRENT_DATE - 1
	AND NOT t.employee_name__c IN ('Charlynne Pinto', 'Nicole Daiter')

GROUP BY 1, 2, 3, 4, 5


---------------------
UNION ALL 
--New Opportunities  
---------------------
SELECT 
	ed.channel__c, 
	DATE(o.createddate), 
	ed.manager_level_1__c,	
	e.employee_name__c,	
	NULL AS correct_assigned_TSR,
	NULL AS total_activities,	
	NULL AS door_knock_RPC,	
	NULL AS account_review,	
	NULL AS follow_up_call,	
	NULL AS face_to_face_meeting,	
	NULL AS base_call_RPC,	
	NULL AS prospecting_call_RPC,	
	NULL AS base_call,
	NULL AS prospecting_call,
	NULL AS email,
	COUNT(o.id) AS new_opps

FROM vicinity.employee e
	JOIN vicinity.employee_detail ed ON e.id = ed.employee__c	
		AND ed.channel__c IN ('Field Sales')
		AND ed.effective_end_date__c IS NULL 
	JOIN ebu.user u ON e.employee_number__c = u.employee_id__c	
		AND u.isactive = TRUE
	JOIN ebu.opportunity o ON u.id = o.createdbyid 

WHERE o.createddate BETWEEN '2019-01-01' AND CURRENT_DATE 
	AND NOT e.employee_name__c IN ('Charlynne Pinto', 'Nicole Daiter')

GROUP BY 1, 2, 3, 4, 5
ORDER BY 1, 2 desc, 5 desc, 3, 4

