package com.octank.promotion;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Map;

import redis.clients.jedis.Jedis; 

import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.boot.web.servlet.server.ConfigurableServletWebServerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/")
public class PromotionController {

	@GetMapping
	public String index() {
		String rtrn = "You called the Promotion microservice!";
		return rtrn;
	}

	@PostMapping
	@ResponseBody
	public ResponseObject postResponseController(@RequestBody CartData cartData) {

		// Initialize variable defaults
		String cartId = cartData.cartId;
		String productId = cartData.productId;
		String couponId = cartData.couponId;
		String discountAmount = "0.00";
		String productEligible = "false";
		
		// Initialize database variables
		String dbUser = "octank_user";
		String dbPass = "Octank1234";
		String connectionString = "jdbc:mysql://octank-database-1.cluster-cnllg3hg8vf5.us-east-2.rds.amazonaws.com/Octank?useSSL=false";
		String dbDriver = "com.mysql.jdbc.Driver";

		/*
		// Test redis
		Jedis j = new Jedis("localhost", 6379);
		System.out.println("Connection to server sucessfully"); 
		//check whether server is running or not 
		System.out.println("Server is running: "+j.ping()); 
		j.set("tutorial-name", "Redis tutorial");
		System.out.println("Sotring string in redis:: " + j.get("tutorial-name"));
		j.close();
		*/

		String redisConn = "localhost";

		// Check if coupon is valid
		String couponValid = isCouponValid(couponId, dbDriver, connectionString, dbUser, dbPass, redisConn);

		// If coupon is valid, check whether it applies to the product passed in the request
		if (couponValid.equals("true")) {
			Map<String, String> productDetails = couponProductDetails(couponId, productId, dbDriver, connectionString, dbUser, dbPass, redisConn);
			productEligible = productDetails.get("productEligible");
			if (productEligible.equals("true")) {
				discountAmount = productDetails.get("discountAmount");
			}  
		}
		
		// Return response payload
		return new ResponseObject(cartId, productId, couponId, productEligible, couponValid, discountAmount);
	}

	@Bean
	public WebServerFactoryCustomizer<ConfigurableServletWebServerFactory>
	webServerFactoryCustomizer() {
		
		// Set the contextPath depending on whether this is running locally or in a container
		// This is necessary to keep the expected URI /promotion across environments
		String contextPath;
		String envVars = System.getenv().toString();
		if (envVars.contains("apple")) {
			contextPath = "/promotion";
		} else {
			contextPath = "";
		}		

		return factory -> factory.setContextPath(contextPath);
	}


	// Check if the coupon is valid
	private static String isCouponValid(String couponId, String dbDriver, String connectionString, String dbUser, String dbPass, String redisConn) {
		// Check cache/database to check whether coupon is valid
		// Query database
		String valid = "false";

		// our SQL SELECT query. 
		// if you only need a few columns, specify them by name instead of using "*"
		String query = "SELECT `valid` FROM `coupon` WHERE `id` = '" + couponId + "';";
		

		Jedis j = new Jedis(redisConn, 6379);
		//System.out.println("Connection to server sucessfully"); 
		//System.out.println("Server is running: "+j.ping()); 
		
		String redisResult = j.get(query);
		if (redisResult != null) {
			valid = redisResult;
			System.out.println("Got value for Valid from cache!");
		} else {
			try {
				// create our mysql database connection
				Class.forName(dbDriver);
				Connection conn = DriverManager.getConnection(connectionString, dbUser, dbPass);
	
				// create the java statement
				Statement st = conn.createStatement();
				
				// execute the query, and get a java resultset
				ResultSet rs = st.executeQuery(query);
				
				// iterate through the java resultset
				while (rs.next())
				{
					valid = String.valueOf(rs.getBoolean("valid"));
					
					// print the results
					System.out.format("%s, %s\n", couponId, valid);
				}
				
				rs.close();
				st.close();
				conn.close();

				// Save the value to cache
				j.set(query, valid);
				j.expire(query, 10);
				//System.out.println("Storing string " + j.get(query) + " in redis for key " + query);
				j.close();

			}
			catch (Exception e) {
				System.err.println("Coupon query failed! ");
				System.err.println(e.getMessage());
			}
		}

		return valid;
	}

	// Get product promotion details
	private static Map<String, String> couponProductDetails(String couponId, String productId, String dbDriver, String connectionString, String dbUser, String dbPass, String redisConn) {
		// Check cache/database to check whether coupon applies to product
		String productEligible = "false";
		String discountAmount = "0.00";

		// our SQL SELECT query. 
		// if you only need a few columns, specify them by name instead of using "*"
		String query = "SELECT pp.product_eligible, c.discount_amount";
		query += " FROM coupon c";
		query += " INNER JOIN product_promotion pp ON c.id = pp.coupon_id";
		query += " WHERE c.id = '" + couponId + "' AND pp.product_id = '" + productId + "';";

		Jedis j = new Jedis(redisConn, 6379);
		//System.out.println("Connection to server sucessfully"); 
		//System.out.println("Server is running: "+j.ping()); 
		
		String redisResult = j.get(query);
		if (redisResult != null) {
			String[] splitResult = redisResult.split("_");
			productEligible = splitResult[0];
			discountAmount = splitResult[1];
			System.out.println("Got value for productEligible and discountAmount from cache!");
		} else {
			try {
				// create our mysql database connection
				Class.forName(dbDriver);
				Connection conn = DriverManager.getConnection(connectionString, dbUser, dbPass);
	
				// create the java statement
				Statement st = conn.createStatement();
				
				// execute the query, and get a java resultset
				ResultSet rs = st.executeQuery(query);
				
				// iterate through the java resultset
				while (rs.next())
				{
					productEligible = String.valueOf(rs.getBoolean("product_eligible"));
					discountAmount = String.valueOf(rs.getDouble("discount_amount"));
					// print the results
					System.out.format("%s, %s\n", productEligible, discountAmount);
				}
				
				rs.close();
				st.close();
				conn.close();

				// Save the value to cache
				j.set(query, productEligible + "_" + discountAmount);
				j.expire(query, 10);
				//System.out.println("Storing string " + j.get(query) + " in redis for key " + query);
				j.close();
			}
			catch (Exception e) {
				System.err.println("Coupon query failed! ");
				System.err.println(e.getMessage());
			}
		}
		
		
		
		Map<String, String> returnObject = new HashMap<String, String>();
		returnObject.put("productEligible", productEligible);
		returnObject.put("discountAmount", discountAmount);
		
		return returnObject;
	}

}