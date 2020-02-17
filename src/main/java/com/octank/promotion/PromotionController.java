package com.octank.promotion;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.Map;
import java.util.HashMap;

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
		String connectionString = "jdbc:mysql://octank-database-1.cluster-cnllg3hg8vf5.us-east-2.rds.amazonaws.com/Octank";
		String dbDriver = "com.mysql.jdbc.Driver";

		// Check if coupon is valid
		boolean isCouponValid = isCouponValid(couponId, dbDriver, connectionString, dbUser, dbPass);
		String couponValid = String.valueOf(isCouponValid);

		// If coupon is valid, check whether it applies to the product passed in the request
		if (couponValid.equals("true")) {
			Map<String, String> productDetails = couponProductDetails(couponId, productId, dbDriver, connectionString, dbUser, dbPass);
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
	private static boolean isCouponValid(String couponId, String dbDriver, String connectionString, String dbUser, String dbPass) {
		// Check cache/database to check whether coupon is valid
		// Query database
		boolean valid = false;
		try {
			// create our mysql database connection
			Class.forName(dbDriver);
			Connection conn = DriverManager.getConnection(connectionString, dbUser, dbPass);
			
			// our SQL SELECT query. 
			// if you only need a few columns, specify them by name instead of using "*"
			String query = "SELECT `id`, `valid` FROM `coupon` WHERE `id` = '" + couponId + "';";

			// create the java statement
			Statement st = conn.createStatement();
			
			// execute the query, and get a java resultset
			ResultSet rs = st.executeQuery(query);
			
			// iterate through the java resultset
			while (rs.next())
			{
				String coupon_id = rs.getString("id");
				valid = rs.getBoolean("valid");
				
				// print the results
				System.out.format("%s, %s\n", coupon_id, valid);
			}
			
			st.close();
		}
		catch (Exception e) {
			System.err.println("Coupon query failed! ");
			System.err.println(e.getMessage());
		}
		return valid;
	}

	// Get product promotion details
	private static Map<String, String> couponProductDetails(String couponId, String productId, String dbDriver, String connectionString, String dbUser, String dbPass) {
		// Check cache/database to check whether coupon applies to product
		boolean productEligible = false;
		double discountAmount = 0.00;
		try {
			// create our mysql database connection
			Class.forName(dbDriver);
			Connection conn = DriverManager.getConnection(connectionString, dbUser, dbPass);
			
			// our SQL SELECT query. 
			// if you only need a few columns, specify them by name instead of using "*"
			String query = "SELECT pp.product_eligible, c.discount_amount";
			query += " FROM coupon c";
			query += " INNER JOIN product_promotion pp ON c.id = pp.coupon_id";
			query += " WHERE c.id = '" + couponId + "' AND pp.product_id = '" + productId + "';";

			// create the java statement
			Statement st = conn.createStatement();
			
			// execute the query, and get a java resultset
			ResultSet rs = st.executeQuery(query);
			
			// iterate through the java resultset
			while (rs.next())
			{
				productEligible = rs.getBoolean("product_eligible");
				discountAmount = rs.getDouble("discount_amount");
				// print the results
				System.out.format("%s, %s\n", productEligible, discountAmount);
			}
			
			st.close();
		}
		catch (Exception e) {
			System.err.println("Coupon query failed! ");
			System.err.println(e.getMessage());
		}
		
		Map<String, String> returnObject = new HashMap<String, String>();
		returnObject.put("productEligible", String.valueOf(productEligible));
		returnObject.put("discountAmount", String.valueOf(discountAmount));
		
		return returnObject;
	}

}