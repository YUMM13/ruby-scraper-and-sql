-- final as of right now, survey results talley and sentiment score are still wrong, will need to be fixed in the future
-- recursive cte to get parents
with recursive ancestors as (
    select id, name, parent_id
    from snapshot_squads
    where id = 55427
    union
    select ss.id, ss.name, ss.parent_id
    from snapshot_squads ss
    join ancestors a on a.parent_id = ss.id
),
-- limit to immediate parents (excluding self)
parent_chain as (
    select name from ancestors
    where id != 55427
    order by id desc
    limit 3
),
-- join parent names into one string
parents_string as (
    select string_agg(name, ' > ') as parents
    from parent_chain
),
-- get full name of the squad
squad_info as (
    select id as snapshot_squad_id, name as snapshot_squad_name, squad_id
    from snapshot_squads
    where id = 55427
),
-- calculate sentiment score WRONG
sentiment_score as (
    select round(100.0 * sum(case when sri.value = 3 then 1 else 0 end) / count(*), 2) as score
    from snapshot_response_items sri 
    join factors f on sri.factor_id = f.id 
    where sri.na = false and sri.skipped = false and f.id = 223
),
-- count of each value WRONG
value_counts as (
    select 
        count(case when sri.value = 1 then 1 end) as one_count,
        count(case when sri.value = 2 then 1 end) as two_count,
        count(case when sri.value = 3 then 1 end) as three_count
    from snapshot_response_items sri
    join snapshot_factors sf on sri.factor_id = sf.factor_id
    join snapshot_squads ss on sf.snapshot_id = ss.snapshot_id 
    where sri.na = false and sri.skipped = false and ss.id = 55427 and sf.factor_id = 223 and sf.snapshot_id = 2849
),
-- team size
team_size_cte as (
    select count(*) as team_size
    from snapshot_squads ss 
    join users u on ss.squad_id = u.squad_id 
    where ss.id = 55427
),
-- factor info
factor_info as (
    select id as factor_id, name as factor_name 
    from factors 
    where id = 223
),
-- average vs benchmark comparison
avg_cte as (
    select avg(bf.p_50) as p50_avg, avg(bf.p_75) as p75_avg, avg(bf.p_90) as p90_avg 
    from benchmark_factors bf 
    join factors f on f.id = bf.factor_id 
    join snapshot_factors sf on f.id = sf.factor_id
    join snapshot_squads ss on sf.snapshot_id = ss.snapshot_id
    where f.id = 223 and ss.id = 55427 and sf.snapshot_id = 2849 and bf.benchmark_segment_id != 1
),
benchmark_cte as (
    select bf.p_50 as bench_p50, bf.p_75 as bench_p75, bf.p_90 as bench_p90 
    from benchmark_factors bf 
    join factors f on f.id = bf.factor_id 
    join snapshot_factors sf on f.id = sf.factor_id
    join snapshot_squads ss on sf.snapshot_id = ss.snapshot_id
    where f.id = 223 and ss.id = 55427 and sf.snapshot_id = 2849 and bf.benchmark_segment_id = 1
),
comparison as (
    select
        case when p50_avg > bench_p50 then '+' || round(abs(p50_avg - bench_p50), 2) 
             else '-' || round(abs(p50_avg - bench_p50), 2) end as p50_trend,
        case when p75_avg > bench_p75 then '+' || round(abs(p75_avg - bench_p75), 2) 
             else '-' || round(abs(p75_avg - bench_p75), 2) end as p75_trend,
        case when p90_avg > bench_p90 then '+' || round(abs(p90_avg - bench_p90), 2) 
             else '-' || round(abs(p90_avg - bench_p90), 2) end as p90_trend
    from avg_cte, benchmark_cte
)
-- final selection
select 
    si.snapshot_squad_id,
    si.snapshot_squad_name,
    ps.parents,
    ss.score,
    vc.one_count,
    vc.two_count,
    vc.three_count,
    ts.team_size,
    fi.factor_id,
    fi.factor_name
from squad_info si
join parents_string ps on true
join sentiment_score ss on true
join value_counts vc on true
join team_size_cte ts on true
join factor_info fi on true;