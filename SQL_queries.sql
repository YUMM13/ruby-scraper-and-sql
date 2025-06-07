Snapshots:
-- snapshot squad name and id DONE 
    select id, name from snapshot_squads;

-- snapshot squad names of heirarchy DONE
    with recursive ancestors as (
        select ss0.id, ss0.name, ss0.parent_id from snapshot_squads ss0 
        where id = 55427
        union
        select ss1.id, ss1.name, ss1.parent_id from snapshot_squads ss1
        join ancestors a on a.parent_id = ss1.id
    ) select name from ancestors limit 3 offset 1;

-- sentiment score for a factor (score across entire factor, does not take squad into account):
    select round(100.0 * sum(case when sri.value = 3 then 1 else 0 end) / count(*), 2) as sentiment_score
        from snapshot_response_items sri join factors f on sri.factor_id = f.id 
        where sri.na = false and sri.skipped = false;

-- total number of people who marked 1 (close)
    select count(*) from snapshot_response_items sri
        join snapshot_factors sf on sri.factor_id = sf.factor_id
        join snapshot_squads ss on sf.snapshot_id = ss.snapshot_id 
        where sri.value = 1 and sri.na = false and sri.skipped = false and ss.id = 55427 and sf.factor_id = 223 and sf.snapshot_id = 2849;

-- total people on a snapshot squad DONE
    select count(*) from snapshot_squads ss join users u on ss.squad_id = u.squad_id where ss.id = 55427;

-- how the snapshot scored against the benchmark (benchmark_segments.id = 1) at p50, p75, and p90 DONE
    with avg as (
    select AVG(bf.p_50) as p50_avg, AVG(bf.p_75) as p75_avg, AVG(bf.p_90) as p90_avg from 
            benchmark_factors bf join factors f on f.id=bf.factor_id 
            join snapshot_factors sf on f.id = sf.factor_id
            join snapshot_squads ss on sf.snapshot_id = ss.snapshot_id
            where f.id = 223 and ss.id = 55427 and sf.snapshot_id = 2849 and bf.benchmark_segment_id != 1
    ),
    benchmark as (
    select bf.p_50 as bench_p50, bf.p_75 as bench_p75, bf.p_90 as bench_p90 from 
            benchmark_factors bf join factors f on f.id=bf.factor_id 
            join snapshot_factors sf on f.id = sf.factor_id
            join snapshot_squads ss on sf.snapshot_id = ss.snapshot_id
            where f.id = 223 and ss.id = 55427 and sf.snapshot_id = 2849 and bf.benchmark_segment_id = 1
    )
    select
        case when p50_avg > bench_p50 then '+' || round(abs(p50_avg - bench_p50), 2) else '-' || round(abs(p50_avg - bench_p50), 2) end as p50_trend,
        case when p75_avg > bench_p75 then '+' || round(abs(p75_avg - bench_p75), 2) else '-' || round(abs(p75_avg - bench_p75), 2) end as p75_trend,
        case when p90_avg > bench_p90 then '+' || round(abs(p90_avg - bench_p90), 2) else '-' || round(abs(p90_avg - bench_p90), 2) end as p90_trend
    from avg, benchmark;
-- factor id and name DONE
    select id, name from factors;

