import { LightningElement, api, track} from 'lwc';
import { subscribe, unsubscribe} from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { LABEL } from 'c/labelsComponent';

export default class LiveLoyalty extends LightningElement {

    @api
    recordId;
    @track
    orders = [];

    channelName = '/event/PostmanPurchase__e';
    subscription;

    label = LABEL;

    connectedCallback() {
        this.handleSubscribe();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    handleSubscribe() {

        const messageCallback = (response) => {
            this.handleEvent(response.data.payload);
        };

        subscribe(this.channelName, -1, messageCallback).then((response) => {
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription);
    }

    handleEvent(payload) {
        
        const eventContactId = payload.ContactId__c; 
        const orderId = payload.OrderId__c; 
        const orderDate = payload.PurchaseDate__c;
        const totalCurrency = payload.TotalCurrency__c;
        const totalPoints = payload.TotalPoints__c;

        if (eventContactId.substring(0, 15) === this.recordId.substring(0, 15)) {
            
            const newOrder = {
                id: orderId,
                date: new Date(orderDate).toLocaleString(),
                currency: totalCurrency,
                points: totalPoints
            };

            this.orders = [newOrder, ...this.orders];

            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.livePurchase,
                    message: `${this.label.newPurchase}: ${totalCurrency}, ${totalPoints} ${this.label.points}`,
                    variant: 'success',
                    mode: 'dismissible'
                })
            );
        }
    }

    get hasOrders() {
        return this.orders.length > 0;
    }
}