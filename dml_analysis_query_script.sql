-- CUSTOMER GROWTH ANALYSIS
-- Annual Customers Analysis
with
	-- ordering customers
	order_cust as(
		select 
			o.order_id,
			o.order_purchase_timestamp,
			cs.customer_unique_id
		from orders o
		inner join customers cs
		on o.customer_id = cs.customer_id
	),
	-- monthly active users
	mau_cnt as (
		select
			extract(year from oc.order_purchase_timestamp) as order_year,
			extract(month from oc.order_purchase_timestamp) as order_month,
			count(distinct oc.customer_unique_id) active_user_cnt
		from order_cust oc
		group by 1, 2
	),
	-- average monthly active users
	avg_mau as (
		select 
			order_year,
			avg(active_user_cnt) as avg_mau
		from mau_cnt
		group by 1
		order by 1
	),
	-- new customers
	new_cust as (
		select min(oc.order_purchase_timestamp) as first_order_date,
		oc.customer_unique_id
		from order_cust oc
		group by 2
	),
	-- annually new customers count
	annually_new_cust as (
		select
			extract(year from nc.first_order_date) as order_year,
			count(nc.customer_unique_id) as new_cust_cnt
		from new_cust nc
		group by 1
		order by 1
	),
	-- order count by cust
	order_cnt_cust as (
		select
			extract(year from oc.order_purchase_timestamp) as order_year,
			oc.customer_unique_id,
			count(oc.order_id) as order_count
		from order_cust oc
		group by 1, 2
		order by 1
	),
	-- annually repeat order cust
	annually_rep_cust as (
		select
			occ.order_year,
			count(occ.customer_unique_id) as rep_cust_cnt
		from order_cnt_cust occ
		where occ.order_count > 1
		group by 1
		order by 1
	),
	-- annually order count average by cust
	annually_avg_order_cnt as (
		select
			occ.order_year,
			avg(occ.order_count) avg_order_cnt
		from order_cnt_cust occ
		group by 1
		order by 1
	)
-- merge avg_mau, annually_new_cust, annually_rep_cust, and annually_avg_order_cnt
select 
	am.order_year as "Year",
	am.avg_mau as "Avg. MAU",
	anc.new_cust_cnt as "Cnt. New Customers",
	arc.rep_cust_cnt as "Cnt. Repeated Order Cust.",
	aaoc.avg_order_cnt as "Avg. Order Count by Cust"
from avg_mau am
join annually_new_cust anc
on am.order_year = anc.order_year
join annually_rep_cust arc
on am.order_year = arc.order_year
join annually_avg_order_cnt aaoc
on am.order_year = aaoc.order_year;


-- PRODUCT CATEGORY PERFORMANCE ANALYSIS
-- Annually Order and Revenue Performance
create table annually_order_revenue as (
	with
		order_values as (
			select 
				o.order_id,
				extract (year from o.order_purchase_timestamp) as order_year,
				o.order_status,
				(oi.price + oi.freight_value) as revenue
			from orders o
			inner join order_items oi
			on o.order_id = oi.order_id
		),
		-- annually revenue
		annually_revenue as (
			select
				ov.order_year,
				sum(ov.revenue) as total_revenue
			from order_values ov
			where ov.order_status = 'delivered'
			group by 1
			order by 1
		),
		-- annually cancel order count
		annually_canceled_cnt as (
			select
				extract(year from o.order_purchase_timestamp) as order_year,
				count(o.order_status) as cancel_cnt
			from orders o
			where o.order_status = 'canceled'
			group by 1
			order by 1
		)
	--merge annually_revenue and annually_canceled_cnt
	select 
		ar.order_year,
		ar.total_revenue,
		acc.cancel_cnt
	from annually_revenue ar
	join annually_canceled_cnt acc
	on ar.order_year = acc.order_year
);


-- Annually Product Category Performance
create table category_performance as (
	with
		product_cat_values as (
			select
				extract (year from o.order_purchase_timestamp) as order_year,
				o.order_status,
				(oi.price + oi.freight_value) as revenue,
				pr.product_category_name
			from orders o
			inner join order_items oi
			on o.order_id = oi.order_id
			inner join products pr
			on oi.product_id = pr.product_id
		),
		-- category rank by revenue
		cat_revenue_rank as (
			select
				pcv.order_year,
				pcv.product_category_name,
				sum(pcv.revenue) as revenue,
				row_number() over(partition by pcv.order_year order by sum(pcv.revenue) desc) as cat_rank
			from product_cat_values pcv
			where pcv.order_status = 'delivered'
			group by 1, 2
			order by 1
		),
		-- Top Category by Revenue per Year
		top_category as (
			select 
				crr.order_year,
				crr.product_category_name,
				crr.revenue
			from cat_revenue_rank crr
			where crr.cat_rank = 1
			order by 1
		),
		-- Category Rank by Canceled
		cat_cancel_rank as (
			select
				pcv.order_year,
				pcv.product_category_name,
				count(pcv.product_category_name) as cnt_cancel,
				row_number() over(partition by pcv.order_year order by count(pcv.product_category_name) desc) as cat_rank
			from product_cat_values pcv
			where pcv.order_status = 'canceled'
			group by 1, 2
			order by 1
		),
		-- Top canceled Category
		top_canceled as (
			select 
				ccr.order_year,
				ccr.product_category_name,
				ccr.cnt_cancel
			from cat_cancel_rank ccr
			where ccr.cat_rank = 1
			order by 1
		)
	-- merge top_category and top_canceled
	select 
		tc.order_year,
		tc.product_category_name as top_revenue_cat,
		tc.revenue as cat_revenue,
		tcn.product_category_name as top_canceled_cat,
		tcn.cnt_cancel as cat_cancel_cnt
	from top_category tc
	inner join top_canceled tcn
	on tc.order_year = tcn.order_year
);

-- Merge annually_order_revenue and category_performance
select
	aor.order_year as "Year",
	aor.total_revenue as "Total Revenue",
	aor.cancel_cnt as "Total Cancel Cnt.",
	cp.top_revenue_cat as "Top Revenue Cat.",
	cp.cat_revenue as "Cat. Revenue",
	cp.top_canceled_cat as "Top Canceled Cat.",
	cp.cat_cancel_cnt as "Cat. Cancel Cnt."
from annually_order_revenue aor
inner join category_performance cp
on aor.order_year = cp.order_year;


-- PAYMENT TYPE USAGE ANALYSIS
-- All Time Popular Used Payment Type
select
	pm.payment_type as "Payment Type",
	count(pm.order_id) as "Count Used"
from payments pm
group by 1
order by 2 desc;

-- Popular Payment Type each Year
select
	pm.payment_type as "Payment Type",
	sum(
		case extract(year from o.order_purchase_timestamp)
			when 2016 then 1 else 0
		end
	)as "Year 2016",
	sum(
		case extract(year from o.order_purchase_timestamp)
			when 2017 then 1 else 0
		end
	)as "Year 2017",
	sum(
		case extract(year from o.order_purchase_timestamp)
			when 2018 then 1 else 0
		end
	)as "Year 2018"
from orders o
inner join payments pm
on o.order_id = pm.order_id
group by 1
order by 2;
		
