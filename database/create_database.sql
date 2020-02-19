/*
    Database to store state for the following fields:
    String cartId = "1234"; # Derived
    String productId = "5678"; 
    String couponId = "4321";
    String product_eligible = "true";
    String couponValid = "true"; # Derived
    String discountAmount = "0.15";
*/

CREATE DATABASE IF NOT EXISTS Octank;

USE Octank;

CREATE TABLE IF NOT EXISTS coupon (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  name varchar(255) NOT NULL,
  valid boolean NOT NULL,
  discount_amount float NOT NULL,
  PRIMARY KEY (id)
) ENGINE = InnoDB, AUTO_INCREMENT=10000;

INSERT INTO coupon (`name`, `valid`, `discount_amount`) 
VALUES ('SAVE25', true, 0.25),
       ('SAVE15', false, 0.15),
       ('SPRING30', false, 0.30),
       ('SUMMER20', true, 0.20),
       ('FALL15', false, 0.15),
       ('WINTER50', false, 0.50),
       ('RANGERSWIN', true, 0.25),
       ('COWBOYSWIN', true, 0.10),
       ('LABORDAY35', false, 0.35),
       ('FREEBIE', true, 1.00);

SELECT * FROM coupon;

CREATE TABLE product_promotion (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  coupon_id int(10) unsigned NOT NULL,
  product_id int(10) unsigned NOT NULL,
  product_eligible boolean NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (coupon_id) REFERENCES coupon (id) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB, AUTO_INCREMENT=20000;

INSERT INTO product_promotion (`coupon_id`, `product_id`, `product_eligible`)
VALUES (10000, '20000', true),
       (10000, '20001', true),
       (10000, '20002', true),
       (10000, '20003', true),
       (10000, '20004', true),
       (10001, '20000', true),
       (10001, '20001', false),
       (10001, '20002', true),
       (10001, '20003', false),
       (10001, '20004', true),
       (10002, '20000', true),
       (10002, '20001', true),
       (10002, '20002', true),
       (10002, '20003', true),
       (10002, '20004', true),
       (10003, '20000', false),
       (10003, '20001', false),
       (10003, '20002', false),
       (10003, '20003', false),
       (10003, '20004', true),
       (10004, '20000', true),
       (10004, '20001', true),
       (10004, '20002', false),
       (10004, '20003', true),
       (10004, '20004', true),
       (10005, '20000', true),
       (10005, '20001', false),
       (10005, '20002', true),
       (10005, '20003', false),
       (10005, '20004', true),
       (10006, '20000', false),
       (10006, '20001', false),
       (10006, '20002', true),
       (10006, '20003', true),
       (10006, '20004', true),
       (10007, '20000', false),
       (10007, '20001', true),
       (10007, '20002', true),
       (10007, '20003', false),
       (10007, '20004', false),
       (10008, '20000', true),
       (10008, '20001', true),
       (10008, '20002', false),
       (10008, '20003', true),
       (10008, '20004', true),
       (10009, '20000', true),
       (10009, '20001', false),
       (10009, '20002', false),
       (10009, '20003', true),
       (10009, '20004', true);

SELECT * FROM product_promotion;

SELECT pp.product_id, c.id AS 'coupon_id', pp.product_eligible, c.valid AS 'coupon_valid', c.discount_amount
FROM coupon c
INNER JOIN product_promotion pp ON c.id = pp.coupon_id;

CREATE USER IF NOT EXISTS octank_user@'%' IDENTIFIED BY 'Octank1234';
GRANT SELECT ON Octank.* TO octank_user@'%';
