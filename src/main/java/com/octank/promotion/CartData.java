package com.octank.promotion;

import java.util.HashMap;
import java.util.Map;

public class CartData {
    public String cartId;
    public String productId;
    public String quantity;
    public String couponId;

    public CartData(String cartId, String productId, String quantity, String couponId) {
        this.cartId = cartId;
        this.productId = productId;
        this.quantity = quantity;
        this.couponId = couponId;
    }

	public Map<String, String> getCartData() {
        Map<String, String> returnObject = new HashMap<String, String>();
        returnObject.put("cartId", this.cartId);
        returnObject.put("productId", this.productId);
        returnObject.put("quantity", this.quantity);
        returnObject.put("couponId", this.couponId);
        return returnObject;
    }
}