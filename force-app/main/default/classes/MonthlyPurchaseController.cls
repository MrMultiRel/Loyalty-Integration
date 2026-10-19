public with sharing class MonthlyPurchaseController {

    public class OrderWrapper {
        public String purchaseDate { get; set; }
        public String description { get; set; }
        public List<String> productNames { get; set; }
        public Decimal totalCurrency { get; set; }
        public Decimal totalPoints { get; set; }

        public OrderWrapper(Loyalty_Order__c order) {
            
            this.purchaseDate = order.Purchase_Date__c.format();
            this.description = order.Description__c;
            this.totalCurrency = order.Total_Currency__c;
            this.totalPoints = order.Total_Points__c;
            this.productNames = new List<String>();

            if (order.Loyalty_Orders__r != null) {
                
                for (Loyalty_Order__c child : order.Loyalty_Orders__r) {
                    this.productNames.add(child.Bought_Loyalty_Product__r.Loyalty_Product__r.Name);
                }

            }
        }
    }

    public List<OrderWrapper> monthlyPurchases { get; private set; }
    public Decimal MonthTotalCurrency { get; private set; }
    public Decimal MonthTotalPoints { get; private set; }
    public Boolean hasPurchases { get; private set; }

    public Id contactId { 
        get; 
        set {
            contactId = value;
            if (value != null) {
                getData(value);
            } else {
                clearData();
            }
        } 
    }

    public MonthlyPurchaseController() {
        clearData();
    }

    private void getData(Id contactId) {

        this.monthlyPurchases = new List<OrderWrapper>();
        this.MonthTotalCurrency = 0;
        this.MonthTotalPoints = 0;

        try {
            
            List<Loyalty_Order__c> allOrders = ProductService.getOrders(contactId);
            
            if (allOrders != null) {

                Integer currentMonth = Date.today().month();
                Integer currentYear = Date.today().year();

                for (Loyalty_Order__c order : allOrders) {
                    
                    if (order.Purchase_Date__c.month() == currentMonth && order.Purchase_Date__c.year() == currentYear) {
                        
                        OrderWrapper wrappedOrder = new OrderWrapper(order);
                        this.monthlyPurchases.add(wrappedOrder);
                        
                        this.MonthTotalCurrency += wrappedOrder.totalCurrency;
                        this.MonthTotalPoints += wrappedOrder.totalPoints;
                    }
                }
            }
        } catch(Exception e) {
            throw new AuraHandledException('Unable to get orders: ' + e.getMessage());
        }

        this.hasPurchases = !this.monthlyPurchases.isEmpty();
    }

    private void clearData() {
        this.monthlyPurchases = new List<OrderWrapper>();
        this.MonthTotalCurrency = 0;
        this.MonthTotalPoints = 0;
        this.hasPurchases = false;
    }
}