-- Create Creation

--STORES TABLE
CREATE DATABASE DATASET
GO
USE DATASET
GO

create table stores(
store_id varchar(10) Primary key,
store_name varchar(30),
city varchar(30),
country varchar(30)
);

select * from stores;

--CAREGORIES TABLE

create table category(
category_id varchar(10) primary key,
category_name varchar(30)
);

select * from category;

--PRODUCTS TABLE
drop table products
create table products(
product_id varchar(10) primary key,
product_name varchar(35),
category_id varchar(10),
launch_date date,
price float,
constraint fk_category foreign key (category_id) references category(category_id)
);

select * from product;

--ALTER TABLE product
--ADD CONSTRAINT FK_Product_Category FOREIGN KEY (category_id)
--REFERENCES Category(category_id);

--SALES TABLE
create table sales(
sale_id varchar(10) primary key,
sale_date date,
store_id varchar(10),
product_id varchar(10),
quantity int,
constraint fk_store foreign key (store_id) references stores(store_id),
constraint fk_product foreign key (product_id) references products(product_id)
);

ALTER TABLE sale
ADD CONSTRAINT FK_Sale_Stores FOREIGN KEY (store_id)
REFERENCES Stores(store_id);

ALTER TABLE sale
ADD CONSTRAINT FK_Sale_Product FOREIGN KEY (product_id)
REFERENCES product(product_id);

select * from sale;

--WARRANTY TABLE
drop table warranty
create table warranty(
claim_id varchar(10) primary key,
claim_date date,
sale_id varchar(10),
repair_status varchar(20),
constraint fk_sale foreign key (sale_id) references sales(sale_id)
);

ALTER TABLE warrantys
ADD CONSTRAINT FK_Warranty_Sale FOREIGN KEY (sale_id)
REFERENCES sale(sale_id);

select * from warrantys;

