@isTest
private class LoyaltyWebServiceTest {

    @testSetup
    static void setupTestData() {
        
        TestFactory.getContact('Tester', 'Testerson', 'CARD-005', 1, true);

        List<Loyalty_Product__c> mainProduct = TestFactory.getMainProduct(1, true);
        TestFactory.getPointsProduct(mainProduct, true);
    
    }

    private static void setRestContext() {

        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        request.requestURI = '/services/apexrest/loyalty/buy/';
        request.httpMethod = 'POST';
        
        RestContext.request = request;
        RestContext.response = response;
    }
   
    @isTest
    static void testPurchaseProductsPositive() {
        
        setRestContext();

        Contact contact = [SELECT Card_Number__c FROM Contact LIMIT 1];
        List<Loyalty_Product__c> products = [SELECT Name, Price_Currency__c, Price_Points__c FROM Loyalty_Product__c];
        List<String> productNames = new List<String>{ products[0].Name, products[1].Name };
        Datetime purchaseDate = Datetime.now();
        String description = 'Test Purchase';

        LoyaltyWebService.purchaseProducts(contact.Card_Number__c, productNames, purchaseDate, 'Test Purchase');
        
        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Id mainOrderId = (Id) jsonResponse.get('orderId');
        Loyalty_Order__c mainOrder = [SELECT Id FROM Loyalty_Order__c WHERE Id = :mainOrderId];

        Assert.areEqual(201, RestContext.response.statusCode, 'Expected 201 Created');
        Assert.areEqual('Success', jsonResponse.get('status'), 'Expected Success');
        Assert.areEqual(mainOrder.Id, jsonResponse.get('orderId'), 'Expectd same ID');
    }

    @isTest
    static void testPurchaseProductsNoProducts() {

        setRestContext();
        
        Contact contact = [SELECT Card_Number__c FROM Contact LIMIT 1];

        LoyaltyWebService.purchaseProducts(contact.Card_Number__c, new List<String>(), Datetime.now(), 'Test Purchase No Products');

        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        Assert.areEqual(400, RestContext.response.statusCode, 'Expected 400 Bad Request');
        Assert.areEqual('Product names were not provided' ,jsonResponse.get('error'), 'Expected "Product names were not provided"');
    }

    @isTest
    static void testPurchaseProductsMissingProduct() {

        setRestContext();
        
        Contact contact = [SELECT Card_Number__c FROM Contact LIMIT 1];
        List<String> nonExistentProducts = new List<String>{ 'No Product 1', 'No Product 2' };
        
        LoyaltyWebService.purchaseProducts(contact.Card_Number__c, nonExistentProducts, Datetime.now(), 'Test Purchase Missing Products');

        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        Assert.areEqual(404, RestContext.response.statusCode, 'Expected 404 Not Found');
        Assert.areEqual('Products not found' ,jsonResponse.get('error'), 'Expected "Products not found"');
    }

    @isTest
    static void testPurchaseProductsContactNotFound() {

        setRestContext();
        
        List<Loyalty_Product__c> products = [SELECT Name FROM Loyalty_Product__c];
        List<String> productNames = new List<String>{ products[0].Name };

        LoyaltyWebService.purchaseProducts('CARD-999', productNames, Datetime.now(), 'Test Purchase Invalid Contact');

        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        Assert.areEqual(404, RestContext.response.statusCode, 'Should return 404 Not Found');
        Assert.areEqual('Contact not found' ,jsonResponse.get('error'), 'Expected "Contact not found"');
    }

    @isTest
    static void testPurchaseProductsServerErrorException() {

        setRestContext();       

        Contact contact = [SELECT Card_Number__c FROM Contact LIMIT 1];
        String longDescription = 'A'.repeat(300000);
        List<Loyalty_Product__c> products = [SELECT Name FROM Loyalty_Product__c];
        List<String> productNames = new List<String>{ products[0].Name };

        LoyaltyWebService.purchaseProducts(contact.Card_Number__c, productNames, Datetime.now(), longDescription);

        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        Assert.areEqual(404, RestContext.response.statusCode, 'Should return 404 Not Found');
        Assert.areEqual('Server Error' ,jsonResponse.get('error'), 'Expected "Server Error"');
    }
}