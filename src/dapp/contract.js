import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
       // this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.dataAddress);
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

    generateFlights(callback) {
        let self = this;
        let flights = ["flight1","flight2","flight3"];
        for (var i = 0; i < flights.length; i++) {
            self.flightSuretyApp.methods
            .registerFlight(this.web3.utils.fromAscii("flight1"),1234,this.airlines[0])
            .call({ from: self.owner}, callback);
        }
     }

     isFlightRegistered(flight, callback) {
        let self = this;
        self.flightSuretyApp.methods
        .isFlightRegistered(this.web3.utils.fromAscii("flight1"))
        .call({ from: self.owner}, callback);
     }

     testFunc(callback) {
        let self = this;
        self.flightSuretyApp.methods
        .test2()
        .call({ from: self.owner}, callback);
     }
}