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

INSERT INTO coupon (`name`, `valid`, `discount_amount`) VALUES ('Test Valid Coupon', true, 0.25);
INSERT INTO coupon (`name`, `valid`, `discount_amount`) VALUES ('Test Invalid Coupon', false, 0.15);

SELECT * FROM coupon;

CREATE TABLE product_promotion (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  coupon_id int(10) unsigned NOT NULL,
  product_id int(10) unsigned NOT NULL,
  product_eligible boolean NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (coupon_id) REFERENCES coupon (id) 
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB, AUTO_INCREMENT=10000;

INSERT INTO product_promotion (`coupon_id`, `product_id`, `product_eligible`)
VALUES (10000, '12345', true),
       (10000, '54321', true),
       (10000, '67890', true),
       (10000, '98765', true),
       (10000, '45634', true),
       (10001, '12345', false),
       (10001, '54321', false),
       (10001, '67890', false),
       (10001, '98765', false),
       (10001, '45634', false);

SELECT * FROM product_promotion;

SELECT pp.product_id, c.id AS 'coupon_id', pp.product_eligible, c.valid AS 'coupon_valid', c.discount_amount
FROM coupon c
INNER JOIN product_promotion pp;

CREATE USER IF NOT EXISTS octank_user@'%' IDENTIFIED BY 'Octank1234';
GRANT SELECT ON Octank.* TO octank_user@'%';
