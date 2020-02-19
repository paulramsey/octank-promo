package com.octank.promotion;

import java.util.Arrays;

import javax.servlet.Filter;
import com.amazonaws.xray.javax.servlet.AWSXRayServletFilter;
import com.amazonaws.xray.strategy.DynamicSegmentNamingStrategy;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@SpringBootApplication
public class PromotionApplication extends SpringBootServletInitializer {

	@Value("${cache.enabled}") String cacheEnabled;
	
	@Override
	protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
		return application.sources(PromotionApplication.class);
	}
	public static void main(String[] args) {
		SpringApplication.run(PromotionApplication.class, args);
	}

	@Bean
	public CommandLineRunner commandLineRunner(ApplicationContext ctx) {
		return args -> {

			System.out.println("Let's inspect the beans provided by Spring Boot:");

			String[] beanNames = ctx.getBeanDefinitionNames();
			Arrays.sort(beanNames);
			for (String beanName : beanNames) {
				System.out.println(beanName);
			}

			System.out.println("Cache enabled?: " + cacheEnabled);

		};
	}

	@Configuration
	public class WebConfig {

		@Bean
		public Filter TracingFilter() {
			return new AWSXRayServletFilter(new DynamicSegmentNamingStrategy("/promotion", "*.example.com"));
		}
	}

}
