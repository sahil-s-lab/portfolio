WITH
  recursive campaigns AS -- CHOSE TARGET TOP-UP CAMPAIGNS WITH ID'S BELOW
  (
    SELECT DISTINCT
      c.id,
      c.name,
      COUNT(m.id)
    FROM
      ebu.campaign c
    JOIN
      ebu.campaign_member m
    ON
      c.id = m.campaignid
    WHERE
      m.assigned_to_full_name__c = 'Stuart Brown'
    AND
      m.status = 'Reserve'
    AND
      c.startdate <= CURRENT_DATE
    AND
      c.enddate >= CURRENT_DATE
    GROUP BY
      1,2



  )
  ,
  -- reserved campaign members where assigned_to__c = 'Stuart Brown'
  -- row_number is sequenced by campaignid
  reserved AS
  (
    SELECT
      row_number() over(PARTITION BY cm.campaignid),
      c.name campaign_name,
      cm.campaignid,
      cm.id campaign_member_id
    FROM
      campaigns c
    JOIN ebu.user u
    ON
      u.name = 'Stuart Brown'
    JOIN ebu.campaign_member cm
    ON
      cm.campaignid = c.id
    AND cm.assigned_to__c = u.id
    AND cm.isdeleted = 'f'
  )
  ,
  usage AS
  (
    SELECT
      u.name user_name,
      u.id owner_id,
      40-COUNT(
        CASE
          WHEN m.status = 'New'
          THEN m.id
          ELSE NULL
        END) num_add,
      c.id campaignid,
      SUM(
        CASE
          WHEN m.status = 'New'
          THEN 1
          ELSE 0
        END) num_new,
      SUM(
        CASE
          WHEN m.status = 'In Progress'
          THEN 1
          ELSE 0
        END) num_in_progress,
      COUNT(m.id) num_total
    FROM
      ebu.campaign_member m
    JOIN ebu.campaign c
    ON
      c.id = m.campaignid
    JOIN ebu.user u
    ON
      u.id = m.assigned_to__c
    WHERE
      c.id IN
      (
        SELECT
          id
        FROM
          campaigns
      )
    AND m.assigned_to_director__c IN ('Steve Furman','Kristine Peticca')
 
    GROUP BY
      1,2,4
    ORDER BY
      2,3 ASC
  )
  ,
  -- expand usage to one row per num_add
  expand_list AS
  (
    SELECT
      1 n,
      owner_id,
      campaignid,
      num_add
    FROM
      usage
    WHERE
	num_total < 250
    AND
        num_new < 30
    AND
	num_in_progress < (num_total - num_new) * 0.55
        
    UNION ALL
    SELECT
      n+1,
      owner_id,
      campaignid,
      num_add
    FROM
      expand_list
    WHERE
      n < num_add
  )
  ,
  -- sequence expand_list by campaignid
  expand_by_campaign AS
  (
    SELECT
      row_number() over (PARTITION BY campaignid ORDER BY owner_id) ,
      campaignid,
      owner_id,
      num_add
    FROM
      expand_list
  )
SELECT
  x.campaignid campaign_id,
  r.campaign_name,
  x.owner_id assigned_to__c,
  u.name,
  x.row_number ,
  x.num_add,
  r.campaign_member_id id,
  l.id lead_id,
  c.id contact_id,
  'New' status,
  l.state,
  c.mailingstate
FROM
  expand_by_campaign x
JOIN reserved r
ON
  r.row_number = x.row_number
AND r.campaignid = x.campaignid
JOIN ebu.user u ON u.id = x.owner_id
LEFT JOIN ebu.campaign_member m ON m.id = r.campaign_member_id
LEFT JOIN ebu.lead l ON l.id = m.leadid
LEFT JOIN ebu.contact c ON c.id = m.contactid
ORDER BY
  x.campaignid,
  x.owner_id ,
  x.row_number ;
