create database music_store;
drop database music_store;


CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE dannys_diner.sales (
customer_id VARCHAR(1),
order_date DATE,
product_id INTEGER );

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name,price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  -- 1. What is the total amount each customer spent at the restaurant?
 -- select * from members;
 -- select * from sales;
 -- select * from menu;
 -- answer 
  select s.customer_id,sum(price) as total_spent from sales as s
  join menu as m
  on s.product_id=m.product_id
  group by s.customer_id ;
  
  -- 2. How many days has each customer visited the restaurant?
  select customer_id,count(customer_id) as days_visited 
  from sales
  group by customer_id;
  
  
  -- 3. What was the first item from the menu purchased by each customer?
  with cte as (
  select s.customer_id,s.order_date,m.product_id,m.product_name from sales as s
  join menu as m
  on s.product_id=m.product_id)
  select * from(
  select customer_id,order_date,product_name,
  dense_rank() over (partition by customer_id order by order_date) as rn
  from cte ) as a 
  where rn=1;
  
  -- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
  
  select count(s.product_id) as purchased ,product_name from sales as s
  join menu as m
  on s.product_id=m.product_id
  group by s.product_id
  order by purchased desc
  limit 1;
  
  select customer_id,count(s.product_id) as purchased ,product_name
  from sales as s
  join menu as m
  on s.product_id=m.product_id
  where product_name like "ramen"
  group by customer_id;

  
  select customer_id,count(s.product_id) as purchased ,product_name
  from sales as s
  join menu as m
  on s.product_id=m.product_id
  where m.product_id=(
   select s.product_id from sales as s
  group by s.product_id
  order by count(s.product_id) desc
  limit 1) 
  group by  customer_id;
  
  -- 5. Which item was the most popular for each customer?
  with cte as (
  select customer_id,count(s.product_id) as number_of_times_purchased,product_name
  from sales as s
  join menu as m
  on s.product_id=m.product_id
  group by  customer_id,product_name
   )
   select * from (
  select *,dense_rank() over (partition by customer_id order by cte.number_of_times_purchased desc  ) as dn
  from cte ) a 
  where dn=1;
  
  
-- 6. Which item was purchased first by the customer after they became a member?
select s.customer_id,m.join_date,product_name from members as m
join sales as s
on s.order_date=m.join_date
join menu as mu
on s.product_id=mu.product_id ;

-- 7. Which item was purchased just before the customer became a member?
  select * from sales;
  select * from members;
  select * from menu;
  
  
  with cte as (
  select  s.customer_id,s.order_date,s.product_id,product_name
  from sales as s
  join members as m
  on  s.customer_id=m.customer_id
  join menu as mu
  on s.product_id=mu.product_id
  where s.order_date < m.join_date
  
  order by customer_id,order_date desc)
  select * from(
  select *,dense_rank() over (partition by cte.customer_id order by cte.order_date desc ) as dn
  from cte  ) as a
  where dn=1 ;
  
  select  s.customer_id,s.order_date,s.product_id,product_name
  from sales as s
  join members as m
  on  s.customer_id=m.customer_id
  join menu as mu
  on s.product_id=mu.product_id
  where s.order_date < m.join_date
  and s.order_date=
  (select max(order_date) from sales as s2
   where s.customer_id=s2.customer_id
   and  s2.order_date < m.join_date )
   order by customer_id;
   
  
  -- 8. What is the total items and amount spent for each member before they became a member?
 ''' select s.customer_id,order_date,s.product_id,m.product_name,m.price as amount
  from sales as s 
  join members as mem
  on s.customer_id=mem.customer_id
  join menu as m
  on s.product_id=m.product_id
  where s.order_date < mem.join_date

  order by customer_id;'''
  
  select s.customer_id,count(s.product_id) as total_items ,sum(m.price) as total_amount
  from sales as s 
  join members as mem
  on s.customer_id=mem.customer_id
  join menu as m
  on s.product_id=m.product_id
  where s.order_date < mem.join_date
  group by s.customer_id
  order by customer_id
  
  --9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
  
  select s.customer_id,
  sum(case when product_name='sushi' then price* 10 *2
	   else price *10  end) as total_points
  from sales as s
  join menu as m
  on s.product_id=m.product_id
  group by s.customer_id
  order by total_points desc;
  
  
  -- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
; 
  select s.customer_id,
  sum(case when order_date between join_date  and adddate(mem.join_date,interval 7 day) then price *10 * 2
      else price *10 end) as total_points
  from sales as s
  join menu as m
  on s.product_id=m.product_id
  join members as mem
  on s.customer_id=mem.customer_id
  where s.customer_id in ('A','B')
  and s.order_date between mem.join_date  and '2021-01-31'
  group by s.customer_id
  order by total_points desc;