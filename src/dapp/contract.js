import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        //this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.dataAddress);
        //console.log(config.dataAddress);
        //web3.eth.contract(abi).new(param1,param2,{data:code}, callback);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

     generateFlight(flight, callback) {
        let self = this;
        let time = Number(Math.floor(Date.now() / 1000));
        self.flightSuretyApp.methods     
        .registerFlight(this.web3.utils.fromAscii(flight),time,this.airlines[0])
        .send({ from: self.owner}, callback);    
     }

     isFlightRegistered(flight,callback) {
        let self = this;
        self.flightSuretyApp.methods      
        .isFlightRegistered(this.web3.utils.fromAscii(flight))
        .call({ from: self.owner}, callback);
     }

     fundAirline(callback) {
        let self = this;
        const amount = 10;
        const amountToSend = this.web3.utils.toWei(amount.toString(), "ether");
        self.flightSuretyApp.methods
        .fundAirline()
        .send({from:self.airlines[0],value: amountToSend}, callback);
     }

     buyInsurace(flight,insuranceValue,callback) {
        let self = this;
        const amount = insuranceValue;
        const amountToSend = this.web3.utils.toWei(amount.toString(), "ether");
        self.flightSuretyApp.methods
        // .buy(this.web3.utils.fromAscii("flight1"))
        .buy(this.web3.utils.fromAscii(flight))
        .send({ from: self.owner, value: amountToSend, gas: 1000000}, callback);
     }

     submitToOracles(callback) {
        let self = this;
        self.flightSuretyApp.methods
        .creditInsurees(this.web3.utils.fromAscii("flight1"))
        .send({ from: self.owner}, callback);
     }

     creditInsureesTest(callback) {
        let self = this;
        self.flightSuretyApp.methods
        .creditInsurees(this.web3.utils.fromAscii("flight1"))
        .send({ from: self.owner}, callback);
     }

     returnCreditAmount(callback) {
        let self = this;
        self.flightSuretyApp.methods
        .returnCreditAmount()
        .call({ from: self.owner}, callback);
     }

     payoutInsurance(callback) {
        let self = this;
        self.flightSuretyApp.methods        
        .withdrawl()
        .send({ from: self.owner}, callback);
     }     

     fetchFlightStatus(flight,callback) {
        console.log("fetchFlightStatus",flight);
        let self = this;
        let time = Number(Math.floor(Date.now() / 1000));
        self.flightSuretyApp.methods        
        .fetchFlightStatus(self.airlines[0],flight,time)
        .send({ from: self.owner}, callback);
     } 

     //show user's current balance
     showUserBalance(callback) {
        let self = this;
        this.web3.eth.getBalance(self.owner).then(function(value){
            console.log(value)
        });
     } 
}