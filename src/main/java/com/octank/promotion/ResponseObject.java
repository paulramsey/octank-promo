package com.octank.promotion;

import java.util.HashMap;
import java.util.Map;

// Class to allow Spring to auto-format the reponse as JSON
public class ResponseObject {
    String cartId;
    String productId;
    String couponId;
    String productEligible;
    String couponValid;
    String discountAmount;

    // Constructor
    public ResponseObject(String cid, String pid, String cod, String elg, String act, String dis) {
        this.cartId = cid;
        this.productId = pid;
        this.couponId = cod;
        this.productEligible = elg;
        this.couponValid = act;
        this.discountAmount = dis;
    }

    public Map<String, String> getResponseObject() {
        Map<String, String> returnObject = new HashMap<String, String>();
        returnObject.put("cartId", this.cartId);
        returnObject.put("productId", this.productId);
        returnObject.put("couponId", this.couponId);
        returnObject.put("productEligible", this.productEligible);
        returnObject.put("couponValid", this.couponValid);
        returnObject.put("discountAmount", this.discountAmount);
        return returnObject;
    }
    
}