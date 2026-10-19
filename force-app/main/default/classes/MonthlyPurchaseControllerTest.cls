@isTest
private class MonthlyPurchaseControllerTest {

    @testSetup
    static void setupTestData() {
        
        Contact contact = TestFactory.getContact('Tester', 'Testerson', 'CARD-005', 1, true)[0];
        List<Loyalty_Product__c> mainProducts = TestFactory.getMainProduct(2, true);
        List<Bought_Loyalty_Product__c> boughtProducts = TestFactory.getBoughtLoyaltyProduct(mainProducts, contact, true);
        TestFactory.getLoyaltyOrder(boughtProducts, Datetime.now(), true);
        TestFactory.getLoyaltyOrder(boughtProducts, Datetime.now().addMonths(-2), true);

    }

    @isTest
    static void testControllerPositive() {
        
        Contact contact = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        
        MonthlyPurchaseController controller = new MonthlyPurchaseController();
        
        Assert.areEqual(0, controller.MonthTotalCurrency, 'Expected 0');
        Assert.areEqual(0, controller.MonthTotalPoints, 'Expected 0');
        Assert.areEqual(false, controller.hasPurchases, 'Expected false');
        Assert.areEqual(0, controller.monthlyPurchases.size(), 'Expected 0');

        controller.contactId = contact.Id;

        Test.stopTest();

        Assert.areEqual(contact.Id, controller.contactId, 'Expected ' + contact.Id);


        Assert.areEqual(100, controller.MonthTotalCurrency, 'Expected 100');
        Assert.areEqual(0, controller.MonthTotalPoints, 'Expected 0');
        Assert.areEqual(true, controller.hasPurchases, 'Expected true');
        Assert.areEqual(1, controller.monthlyPurchases.size(), 'Expected 1');
    }

    @isTest
    static void testControllerNoPurchases() {
       
        Contact emptyContact = new Contact(LastName = 'No Purchases');
        insert emptyContact;

        Test.startTest();

        MonthlyPurchaseController controller = new MonthlyPurchaseController();
        controller.contactId = emptyContact.Id;

        Test.stopTest();

        Assert.areEqual(0, controller.MonthTotalCurrency, 'Expected 0');
        Assert.areEqual(0, controller.MonthTotalPoints, 'Expected 0');
        Assert.areEqual(false, controller.hasPurchases, 'Expected false');
        Assert.areEqual(0, controller.monthlyPurchases.size(), 'Expected 0');
    }

    @isTest
    static void testControllerNoId() {

        Test.startTest();

        MonthlyPurchaseController controller = new MonthlyPurchaseController();
        controller.contactId = null;

        Test.stopTest();

        Assert.areEqual(0, controller.MonthTotalCurrency, 'Expected 0');
        Assert.areEqual(0, controller.MonthTotalPoints, 'Expected 0');
        Assert.areEqual(false, controller.hasPurchases, 'Expected false');
        Assert.areEqual(0, controller.monthlyPurchases.size(), 'Expected 0');
    }

    @isTest
    static void testControllerException() {
        
        Contact contact = [SELECT Id FROM Contact LIMIT 1];

        Loyalty_Order__c badOrder = new Loyalty_Order__c(
            Purchase_Date__c = null,
            Description__c = 'Bad Test Order',
            Total_Currency__c = 100,
            Total_Points__c = 100
        );
        insert badOrder;

        Bought_Loyalty_Product__c boughtProduct = [SELECT Id FROM Bought_Loyalty_Product__c LIMIT 1];

        Loyalty_Order__c badChildOrder = new Loyalty_Order__c(
            Bought_Loyalty_Product__c = boughtProduct.Id,
            Loyalty_Order__c = badOrder.Id
        );
        insert badChildOrder;

        Test.startTest();

        MonthlyPurchaseController controller = new MonthlyPurchaseController();

        Boolean exceptionThrown = false;
        try {
            
            controller.contactId = contact.Id;
            Assert.fail('Expected exception');

        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Expected true');
    }

}