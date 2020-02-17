package com.octank.promotion;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.Map;

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

		String cartId = cartData.cartId;
		String productId = cartData.productId;
		String couponId = cartData.couponId;
		String eligible = "true";
		String actionable = "true";
		String discountAmount = "0.15";

		boolean isCouponValid = isCouponValid();
		boolean doesCouponApplyToProduct = doesCouponApplyToProduct();

		// Query database
		try {
			// create our mysql database connection
			String myDriver = "com.mysql.jdbc.Driver";
			String myUrl = "jdbc:mysql://octank-database-1.cluster-cnllg3hg8vf5.us-east-2.rds.amazonaws.com/Octank";
			Class.forName(myDriver);
			Connection conn = DriverManager.getConnection(myUrl, "octank_user", "Octank1234");
			
			// our SQL SELECT query. 
			// if you only need a few columns, specify them by name instead of using "*"
			String query = "SELECT pp.product_id, c.id AS 'coupon_id', pp.eligible, pp.actionable, c.discount_amount FROM coupon c INNER JOIN product_promotion pp;";

			// create the java statement
			Statement st = conn.createStatement();
			
			// execute the query, and get a java resultset
			ResultSet rs = st.executeQuery(query);
			
			// iterate through the java resultset
			while (rs.next())
			{
				int product_id = rs.getInt("product_id");
				String coupon_id = rs.getString("coupon_id");
				boolean eligible_l = rs.getBoolean("eligible");
				boolean actionable_l = rs.getBoolean("actionable");
				double discount_amount = rs.getDouble("discount_amount");
				
				// print the results
				System.out.format("%s, %s, %s, %s, %s\n", product_id, coupon_id, eligible_l, actionable_l, discount_amount);
			}
			
			st.close();
		}
		catch (Exception e) {
			System.err.println("Query failed! ");
			System.err.println(e.getMessage());
		}

		return new ResponseObject(cartId, productId, couponId, eligible, actionable, discountAmount);
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

	private static boolean isCouponValid() {
		// Check cache/database to check whether coupon is valid
		return true;
	}

	private static boolean doesCouponApplyToProduct() {
		// Check cache/database to check whether coupon applies to product
		return true;
	}

	private static ResultSet runSql(String stmt) {

	}
}