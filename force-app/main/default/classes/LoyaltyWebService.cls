@RestResource(urlMapping='/loyalty/buy/*')
global with sharing class LoyaltyWebService {

    @HttpPost
    global static void purchaseProducts(String cardNumber, List<String> productNames, Datetime purchaseDate, String description) {
        
        RestResponse response = RestContext.response;

        try {

            if (productNames == null || productNames.isEmpty()) {
                response.statusCode = 400;
                response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                    'error' => System.Label.NamesProvided,
                    'message' => System.Label.ListNames
                }));
                return;
            }

            List<Loyalty_Product__c> products = [SELECT Id, Name FROM Loyalty_Product__c WHERE Name IN :productNames];

            Map<String, Id> nameToIdMap = new Map<String, Id>();
            for (Loyalty_Product__c product : products) {
                nameToIdMap.put(product.Name, product.Id);
            }

            Set<String> missingProducts = new Set<String>(productNames);
            missingProducts.removeAll(nameToIdMap.keySet());

            if (!missingProducts.isEmpty()) {
                response.statusCode = 404;
                response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'error' => System.Label.ProductsFound,
                    'message' => System.Label.ProductDatabase,
                    'missingProducts' => missingProducts
                }));
                return;
            }

            List<Id> productIds = new List<Id>();
            for (String requestedName : productNames) {
                productIds.add(nameToIdMap.get(requestedName));
            }                 

            List<Contact> buyerContacts = [SELECT Id FROM Contact WHERE Card_Number__c = :cardNumber LIMIT 1];

            if (buyerContacts.isEmpty()) {
                response.statusCode = 404;
                response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                    'error' => System.Label.ContactFound,
                    'message' => System.Label.NumberFound
                }));
                return;
            }

            List<Bought_Loyalty_Product__c> boughtProducts = ProductService.insertBought(buyerContacts[0].Id, productIds); 

            Decimal totalCurrency = 0;
            Decimal totalPoints = 0;
                
            for (Bought_Loyalty_Product__c product : boughtProducts) {

                if (product.Loyalty_Product__r.Price_Currency__c != null) {
                    totalCurrency += product.Loyalty_Product__r.Price_Currency__c;
                }

                if (product.Loyalty_Product__r.Price_Points__c != null) {
                    totalPoints += product.Loyalty_Product__r.Price_Points__c;
                }
            }

            List<Loyalty_Order__c> boughtOrders = new List<Loyalty_Order__c>();
            Loyalty_Order__c mainOrder = new Loyalty_Order__c(
                Purchase_Date__c = purchaseDate, 
                Code_Used__c = false, 
                Description__c = description,
                Total_Currency__c = totalCurrency,
                Total_Points__c = totalPoints
            );                
            insert mainOrder;

            for (Integer i = 0; i < boughtProducts.size(); i++) {

                Loyalty_Order__c newOrder = new Loyalty_Order__c(
                    Bought_Loyalty_Product__c = boughtProducts[i].Id, 
                    Loyalty_Order__c = mainOrder.Id
                );

                boughtOrders.add(newOrder);
            }
            insert boughtOrders;

            PostmanPurchase__e purchaseEvent = new PostmanPurchase__e(
                ContactId__c = buyerContacts[0].Id,
                OrderId__c = mainOrder.Id,
                PurchaseDate__c = purchaseDate,
                TotalCurrency__c = totalCurrency,
                TotalPoints__c = totalPoints

            );

            EventBus.publish(purchaseEvent);

            response.statusCode = 201;
            response.responseBody = Blob.valueOf(JSON.serialize(
                new Map<String, Object>{
                    'status' => System.Label.Success,
                    'orderId' => mainOrder.Id,
                    'message' => System.Label.YouPurchased
                }
            ));

        } catch (Exception e) {
            response.statusCode = 404;
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'error' => System.Label.ServerError,
                'message' => e.getMessage()
            }));
        }
    }
}