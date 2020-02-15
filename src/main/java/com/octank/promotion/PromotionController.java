package com.octank.promotion;

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
		boolean isCouponValid = isCouponValid();
		boolean doesCouponApplyToProduct = doesCouponApplyToProduct();

		String cartId = "1234";
		String productId = "5678";
		String couponId = "4321";
		String eligible = "true";
		String actionable = "true";
		String discountAmount = "0.15";

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
}