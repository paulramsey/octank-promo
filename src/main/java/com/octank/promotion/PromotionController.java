package com.octank.promotion;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletResponse;

import com.amazonaws.xray.AWSXRay;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.boot.web.servlet.server.ConfigurableServletWebServerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.HttpClientErrorException;

import redis.clients.jedis.Jedis;

@RestController
@RequestMapping("/")
public class PromotionController {
	
	// Get config values
	@Value("${cache.enabled}") boolean cacheEnabled;
	@Value("${redis.server}") String redisConn;
	@Value("${database.user}") String dbUser;
	@Value("${database.password}") String dbPass;
	@Value("${database.connection.string}") String connectionString;
	@Value("${database.driver}") String dbDriver;
	@Value("${cache.ttl.seconds}") int cacheTTL;

	// Set error response status
	/*
	@ResponseStatus(code = HttpStatus.INTERNAL_SERVER_ERROR)
	class CustomException extends Exception {
		private static final long serialVersionUID = 1L;
	};
	*/

	// Get mapping for basic sanity check
	@GetMapping
	public String index() {
		AWSXRay.beginSubsegment("Test liveness");
		String rtrn = "You called the Promotion microservice!";
		AWSXRay.endSubsegment();
		return rtrn;
	}

	@GetMapping("/warmCache")
	public String warmCacheController() throws Exception {
		String rtrn;
		
		if (!cacheEnabled) {
			rtrn = "Cache is disabled. Nothing to do.";
		} else {
			String[] couponArr = {"10000", "10001", "10002", "10003", "10004", "10005", "10006", "10007", "10008", "10009"};
			String[] productArr = {"20000", "20001", "20002", "20003", "20004"};

			// Warm the coupon cache
			AWSXRay.beginSubsegment("Warm Coupon cache");
			for (String coupon : couponArr) {
				isCouponValid(coupon, dbDriver, connectionString, dbUser, dbPass, redisConn, cacheEnabled, cacheTTL);
			};
			AWSXRay.endSubsegment();

			// Warm the coupon product details cache
			AWSXRay.beginSubsegment("Warm Coupon Product Details cache");
			for (String product : productArr) {
				for (String coupon : couponArr) {
					couponProductDetails(coupon, product, dbDriver, connectionString, dbUser, dbPass, redisConn, cacheEnabled, cacheTTL);
				}
			}
			AWSXRay.endSubsegment();

			rtrn = "You warmed the cache.";
		}
		
		return rtrn;
	}

	// Post mapping for main functionality
	@PostMapping
	@ResponseBody
	public ResponseObject postResponseController(@RequestBody CartData cartData, HttpServletResponse response) throws Exception {

		// Initialize variable defaults
		String cartId = cartData.cartId;
		String productId = cartData.productId;
		String couponId = cartData.couponId;
		String discountAmount = "0.00";
		String productEligible = "false";

		// Placehold for error messages
		String errMessage = "";

		/*
		// Test redis
		Jedis j = new Jedis(redisConn, 6379);
		System.out.println("Connection to server sucessfully"); 
		//check whether server is running or not 
		System.out.println("Server is running: "+j.ping()); 
		j.set("tutorial-name", "Redis tutorial");
		System.out.println("Sotring string in redis:: " + j.get("tutorial-name"));
		j.close();
		*/

		// Check if coupon is valid
		AWSXRay.beginSubsegment("Check if coupon " + couponId + " is valid");
		Map<String, String> couponData = isCouponValid(couponId, dbDriver, connectionString, dbUser, dbPass, redisConn, cacheEnabled, cacheTTL);
		String couponValid = couponData.get("valid");
		if (!couponData.get("errMessage").equals("")) {
			errMessage = couponData.get("errMessage");
		}
		AWSXRay.endSubsegment();

		// If coupon is valid, check whether it applies to the product passed in the request
		AWSXRay.beginSubsegment("Check if coupon " + couponId + " applies to item from cart");
		if (couponValid.equals("true")) {
			Map<String, String> productDetails = couponProductDetails(couponId, productId, dbDriver, connectionString, dbUser, dbPass, redisConn, cacheEnabled, cacheTTL);
			productEligible = productDetails.get("productEligible");
			if (productEligible.equals("true")) {
				discountAmount = productDetails.get("discountAmount");
			}
			if (!productDetails.get("errMessage").equals("")) {
				errMessage += productDetails.get("errMessage");
			}
		}
		AWSXRay.endSubsegment();
		
		// Return response payload
		ResponseObject responseObject = new ResponseObject(cartId, productId, couponId, productEligible, couponValid, discountAmount);
		
		if (!errMessage.equals("")) {
			response.setStatus(503);
			ResponseObject errResponse = new ResponseObject("Error", "Error", "Error", "Error", "Error", "Error");
			return errResponse;
		}

		return responseObject;
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
	private static Map<String, String> isCouponValid(String couponId, String dbDriver, String connectionString, String dbUser, String dbPass, String redisConn, boolean cacheEnabled, int cacheTTL) throws Exception {
		// Check cache/database to check whether coupon is valid
		// Query database
		String valid = "false";

		// Initialize variable to hold error so we can bubble it up to response
		String errMessage = "";

		// our SQL SELECT query. 
		// if you only need a few columns, specify them by name instead of using "*"
		String query = "SELECT `valid` FROM `coupon` WHERE `id` = '" + couponId + "';";
		
		//System.out.println("Connection to server sucessfully"); 
		//System.out.println("Server is running: "+j.ping()); 
		
		String redisResult = null;
		
		if (cacheEnabled) {
			AWSXRay.beginSubsegment("Check cache for coupon " + couponId);
			Jedis j = new Jedis(redisConn, 6379);
			redisResult = j.get(query);
			j.close();
			AWSXRay.endSubsegment();
		}
		
		if (redisResult != null) {
			valid = redisResult;
			//System.out.println("Got value for Valid from cache!");
		} else {
			try {
				AWSXRay.beginSubsegment("Get coupon " + couponId + " from database");
				
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
					//System.out.format("%s, %s\n", couponId, valid);
					//System.out.println("Cache miss or cache disabled. Data retrieved from database.");
				}
				
				rs.close();
				st.close();
				conn.close();
				AWSXRay.endSubsegment();

				if (cacheEnabled) {
					// Save the value to cache
					AWSXRay.beginSubsegment("Save data to cache for coupon " + couponId);
					Jedis j = new Jedis(redisConn, 6379);
					j.set(query, valid);
					j.expire(query, cacheTTL);
					//System.out.println("Storing string " + j.get(query) + " in redis for key " + query);
					j.close();	
					AWSXRay.endSubsegment();
				}
			}
			catch (Exception e) {
				System.err.println("Coupon query failed! ");
				System.err.println(e.getMessage());
				errMessage = e.getMessage();
			}
		}

		Map<String, String> returnObject = new HashMap<String, String>();
		returnObject.put("valid", valid);
		returnObject.put("errMessage", errMessage);
		
		return returnObject;
	}

	// Get product promotion details
	private static Map<String, String> couponProductDetails(String couponId, String productId, String dbDriver, String connectionString, String dbUser, String dbPass, String redisConn, boolean cacheEnabled, int cacheTTL)
			throws Exception {
		// Check cache/database to check whether coupon applies to product
		String productEligible = "false";
		String discountAmount = "0.00";

		// Initialize variable to hold error so we can bubble it up to response
		String errMessage = "";

		// our SQL SELECT query. 
		// if you only need a few columns, specify them by name instead of using "*"
		String query = "SELECT pp.product_eligible, c.discount_amount";
		query += " FROM coupon c";
		query += " INNER JOIN product_promotion pp ON c.id = pp.coupon_id";
		query += " WHERE c.id = '" + couponId + "' AND pp.product_id = '" + productId + "';";
		
		// Connect to redis if enabled
		String redisResult = null;
		if (cacheEnabled) {
			AWSXRay.beginSubsegment("Check cache if coupon " + couponId + " applies to product " + productId);
			Jedis j = new Jedis(redisConn, 6379);
			redisResult = j.get(query);
			j.close();
			AWSXRay.endSubsegment();
		} 

		if (redisResult != null) {
			String[] splitResult = redisResult.split("_");
			productEligible = splitResult[0];
			discountAmount = splitResult[1];
			//System.out.println("Got value for productEligible and discountAmount from cache!");
		} else {
			try {
				AWSXRay.beginSubsegment("Get coupon product details data from database for coupon " + couponId + " and product " + productId);
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
					//System.out.format("%s, %s\n", productEligible, discountAmount);
					//System.out.println("Cache miss or cache disabled. Data retrieved from database.");
				}
				
				// Close DB objects
				rs.close();
				st.close();
				conn.close();
				AWSXRay.endSubsegment();

				if (cacheEnabled) {
					// Save the value to cache
					AWSXRay.beginSubsegment("Save coupon product details data to cache for coupon " + couponId + " and product " + productId);
					Jedis j = new Jedis(redisConn, 6379);
					j.set(query, productEligible + "_" + discountAmount);
					j.expire(query, cacheTTL);
					j.close();
					AWSXRay.endSubsegment();
				}
				

			}
			catch (Exception e) {
				System.err.println("Coupon query failed! ");
				System.err.println(e.getMessage());
				errMessage = e.getMessage();
			}
		}
		
		Map<String, String> returnObject = new HashMap<String, String>();
		returnObject.put("productEligible", productEligible);
		returnObject.put("discountAmount", discountAmount);
		returnObject.put("errMessage", errMessage);
		
		return returnObject;
	}

}