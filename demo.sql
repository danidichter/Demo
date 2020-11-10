--Total Shifts since 2019--
select count(datetimeoffsetbegin)
      from van.tsm_nextgen_eventsignups es
      left join van.tsm_nextgen_eventsignupsstatuses st using(eventsignupid)
      left join rising.turf_sg_mrr t using(vanid)
      left join van.tsm_nextgen_events ev using(eventid)
      where date(es.datetimeoffsetbegin)>=date('{{2019-01-01}}')
        and st.eventstatusname='Completed'
        and es.eventrolename in ('Data Entry/ Admin/ Other', 'Volunteer')
        and es.datesuppressed is null
        and ev.datesuppressed is null
        and state = 'NH'
        
-- Total Calls since 2019--
SELECT
    count (datecanvassed)
  FROM van.tsm_nextgen_contactscontacts_mym a 
  LEFT JOIN van.tsm_nextgen_committees b
    ON a.committeeid = b.committeeid
  LEFT JOIN van.tsm_nextgen_users u
    ON u.userid = a.canvassedby
  WHERE datecanvassed >= date('{{2019-01-01}}')
    AND (a.inputtypeid = 10 --VPB
          OR
         a.inputtypeid = 29 --OpenVPB
          OR
        (a.contacttypeid = 1 AND u.username like '%relaydial%')) 
    and b.committeename = 'NextGen America New Hampshire' 
          --contacted by phone and user is relay API

-- Total Texts since 2019--

-- Total Pledges since 2019--
select nvl(turf_state,geo_state) as state
    , turf
    , count(distinct case when surveyquestionname='OVR 2020' then vanid else null end) as total_ovr
    , count(distinct case when surveyquestionname='Pledge 2020' then vanid else null end) as total_pledges
    , count(distinct case when surveyquestionname='Online VBM Request' then vanid else null end) as total_vbm
    , count(distinct case when surveyquestionname='Petition Signer 2019' then vanid else null end) as total_petition
    , count(distinct case when surveyquestionname='Survey Card 2019' then vanid else null end) as total_survey
  from (
    select csr.vanid
      , t.state as turf_state
      , t.turf
      , c.state as geo_state
      , sq.surveyquestionname
      , datecanvassed
      , date_trunc('week', datecanvassed) as week_canv
      , date_trunc('week', current_timestamp AT TIME ZONE 'PST'-1) as this_week
      , row_number() over (partition by csr.vanid,csr.surveyquestionid order by datecanvassed asc) as row
    from van.tsm_nextgen_contactssurveyresponses_mym csr 
    left join van.tsm_nextgen_surveyquestions sq using(surveyquestionid)
    left join van.tsm_nextgen_surveyresponses sr using(surveyresponseid)
    left join van.tsm_nextgen_contacts_mym c using(vanid)
    left join rising.turf t using(vanid)
    where sq.cycle in (2019, 2020)
      and sq.surveyquestionname in ('Pledge 2020', 'Online VBM Request', 'Petition Signer 2019', 'Survey Card 2019')
      and geo_state is null or geo_state in ('AZ','FL','IA','ME','MI','NC','NH','NV','PA','VA','WI')
      and turf_state is null or turf_state = 'NH'))
