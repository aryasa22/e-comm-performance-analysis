-- Create table customers dataset
create table customers (
	customer_id varchar,
	customer_unique_id varchar,
	customer_zip_code_prefix int,
	customer_city varchar,
	customer_state varchar,
	primary key (customer_id)
);

-- Create table orders dataset
create table orders (
	order_id varchar,
	customer_id varchar,
	order_status varchar,
	order_purchase_timestamp timestamp,
	order_approved_at timestamp,
	order_delivered_carrier_date timestamp,
	order_delivered_customer_date timestamp,
	order_estimated_delivery_date timestamp,
	primary key(order_id),
	foreign key (customer_id) references customers (customer_id) on delete set null
);

-- Create table products dataset
create table products(
	product_id varchar,
	product_category_name varchar,
	product_name_lenght double precision,
	product_description_lenght double precision,
	product_photos_qty double precision,
	product_weight_g double precision,
	product_length_cm double precision,
	product_height_cm double precision,
	poduct_width_cm double precision,
	primary key(product_id)
);

-- Create table sellers dataset
create table sellers(
	seller_id varchar,
	seller_zip_code_prefix int,
	seller_city varchar,
	seller_state varchar,
	primary key(seller_id)
);

-- Create table order items dataset
create table order_items(
	order_id varchar,
	order_item_id int,
	product_id varchar,
	seller_id varchar,
	shipping_limit_date timestamp,
	price double precision,
	freight_value double precision,
	foreign key(order_id) references orders(order_id) on delete set null,
	foreign key(product_id) references products(product_id) on delete set null,
	foreign key(seller_id) references sellers(seller_id) on delete set null
);

-- Create table payments dataset
create table payments (
	order_id varchar,
	payment_sequential int,
	payment_type varchar,
	payment_installments int,
	payment_value double precision,
	foreign key(order_id) references orders(order_id) on delete set null
);

-- Create table reviews dataset
create table reviews(
	review_id varchar,
	order_id varchar,
	review_score int,
	review_comment_title varchar,
	review_comment_message varchar,
	review_creation_date timestamp,
	review_answer_timestamp timestamp,
	foreign key(order_id) references orders(order_id) on delete set null
);

-- Create table geolocations dataset
create table geolocations (
	geolocation_zipcode_prefix int,
	geolocation_lat double precision,
	geolocation_lng double precision,
	geolocation_city varchar,
	geolocation_state varchar
);