# AB Metrics

- Execute the SQL in `supabase/sql/ab_views.sql` in Supabase SQL editor.
- Views:
  - `v_ab_satisfaction`: satisfaction >=4 rate per day by ab_bucket
  - `v_ab_tri_view`: tri-view capture pass rate
  - `v_ab_violation`: deformation violation rate among effect applications
- Query examples:
```sql
select * from v_ab_satisfaction order by d desc limit 30;
```
