insert into app.packages(
    handle,
    partial_name,
    control_description,
    control_relocatable,
    control_requires,
    description_md
)
values ('olirice', 'asciiplot', 'A Toy ASCII Plotting Library', false, '{}',
$asciiplot$
## asciiplot

asciiplot is a toy library for producing ASCII scatterplots for queries in PostgreSQL.

### Installation

```sql
-- Enable dbdev
create extension dbdev;

-- Fetch the package from the package index
dbdev.install('olirice-asciiplot');

-- Create the extension
create schema plot;
create extension "olirice-asciiplot"
    schema 'plot'
    version '0.0.2';
```

### Usage

```sql
create extension asciiplot
select
  plot.scatter(
    val::numeric, --x
    val::numeric, -- y
    'stonks!', -- title
    'time', --x_label
    'value', -- y_label
    15, -- height
    50 --width
  )
from
  generate_series(1,10) vals(val)
```
$asciiplot$
);

insert into app.package_versions(package_id, version_struct, sql)
values (
(select id from app.packages where package_name = 'olirice-asciiplot'),
(0,0,1),
$asciiplot$
CREATE TYPE scatter_state AS (
  x_arr NUMERIC[],
  y_arr NUMERIC[],
  title TEXT,
  x_label TEXT,
  y_label TEXT,
  height INTEGER,
  width INTEGER
);

CREATE OR REPLACE FUNCTION scatter_sfunc(
  state scatter_state,
  x numeric,
  y numeric,
  title TEXT,
  x_label TEXT,
  y_label TEXT,
  height INTEGER,
  width INTEGER
)
RETURNS scatter_state
LANGUAGE plpgsql
AS $$
BEGIN
  state.x_arr := array_append(coalesce(state.x_arr, array[]::numeric[]), x);
  state.y_arr := array_append(coalesce(state.y_arr, array[]::numeric[]), y);
  state.title := coalesce(state.title, title);
  state.x_label := coalesce(state.x_label, x_label);
  state.y_label := coalesce(state.y_label, y_label);
  state.height := coalesce(state.height, height);
  state.width := coalesce(state.width, width);
  RETURN state;
END;
$$;


CREATE OR REPLACE FUNCTION scatter_internal(
  state scatter_state
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  plot text[] := array[]::text[];

  i int := 0;
  j int := 0;
  max_x numeric := max(v) FROM unnest(state.x_arr) arr(v);
  max_y numeric := max(v) FROM unnest(state.y_arr) arr(v);
  min_x numeric := min(v) FROM unnest(state.x_arr) arr(v);
  min_y numeric := min(v) FROM unnest(state.y_arr) arr(v);
  x_range numeric := abs(max_x - min_x);
  y_range numeric := abs(max_y - min_y);

  x_scale numeric := x_range / (state.width);
  y_scale numeric := y_range / (state.height);
  point_idx int;
begin
  for i in 1..state.height loop
    plot := array_append(plot, repeat(' ', state.width));
  end loop;

  for point_idx in 1..array_length(state.x_arr, 1) loop
    i := round((state.y_arr[point_idx] - min_y) / y_scale)::integer;
    j := round((state.x_arr[point_idx] - min_x) / x_scale)::integer;

    plot[i] := overlay(plot[i] placing '*' from j for 1);
  end loop;

  return
          string_agg(v_elem, E'\n'  order by ix desc)
    from
        unnest(plot) with ordinality v_arr(v_elem, ix);
end;
$$;


CREATE AGGREGATE scatter(
  x NUMERIC,
  y NUMERIC,
  title TEXT,
  x_label TEXT,
  y_label TEXT,
  height INTEGER,
  width INTEGER
) (
  STYPE = scatter_state,
  SFUNC = scatter_sfunc,
  FINALFUNC = scatter_internal
);

comment on type scatter_state is e'internal';

$asciiplot$
);


insert into app.package_upgrades(package_id, from_version_struct, to_version_struct, sql)
values (
(select id from app.packages where package_name = 'olirice-asciiplot'),
(0,0,1),
(0,0,2),
$asciiplot$
comment on type scatter_state is e'internal';
$asciiplot$
);
