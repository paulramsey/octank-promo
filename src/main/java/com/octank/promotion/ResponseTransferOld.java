package com.octank.promotion;

// Class to allow Spring to auto-format the reponse as JSON
public class ResponseTransferOld {
    private String text; 

    // Constructor
    public ResponseTransferOld(String initText) {
        setText(initText);
        return;
    }
    
    // Getter
    public String getText() {
        return text;
    }

    // Setter
    public String setText(String newText) {
        text = newText;
        return text;
    }
    
}