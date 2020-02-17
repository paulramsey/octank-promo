package com.octank.promotion;

import java.util.HashMap;
import java.util.Map;

// Class to allow Spring to auto-format the reponse as JSON
public class ResponseObject {
    String cartId;
    String productId;
    String couponId;
    String eligible;
    String actionable;
    String discountAmount;

    // Constructor
    public ResponseObject(String cid, String pid, String cod, String elg, String act, String dis) {
        this.cartId = cid;
        this.productId = pid;
        this.couponId = cod;
        this.eligible = elg;
        this.actionable = act;
        this.discountAmount = dis;
    }

    public Map<String, String> getResponseObject() {
        Map<String, String> returnObject = new HashMap<String, String>();
        returnObject.put("cartId", this.cartId);
        returnObject.put("productId", this.productId);
        returnObject.put("couponId", this.couponId);
        returnObject.put("eligible", this.eligible);
        returnObject.put("actionable", this.actionable);
        returnObject.put("discountAmount", this.discountAmount);
        return returnObject;
    }
    
}