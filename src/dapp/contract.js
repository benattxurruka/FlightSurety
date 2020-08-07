import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
        this.accounts = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];

            this.accounts = accts;

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

    registerAirline(address, name) {
        let self = this;
        let payload = {
            airlineAddress: address,
            name: name
        }
        self.flightSuretyData.methods
            .registerAirline(payload.airlineAddress, payload.name)
            .send({ from: self.owner}, (error, result) => {
                if(error) {
                    console.log(error);
                  } 
                  else {
                    alert('Registered: ' + payload.name);
                    console.log('Registered: ' + payload.name);
                    console.log(payload);
                  }
            });
    }

    fund(funds, callback) {
        let self = this;
        let payload = {
            funds: funds
        } 
        self.flightSuretyData.methods
            .fund()
            .send({ from: self.owner, value: payload.funds}, (error, result) => {
                callback(error, payload);
            });
    }

    registerFlight(flight, destination, callback) {
        let self = this;
        console.log(self.accounts);
        let payload = {
            flight: flight,
            destination: destination,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .registerFlight(payload.flight, payload.destination, payload.timestamp)
            .send({ from: self.accounts[6]}, (error, result) => {
                callback(error, payload);
            });
    }

    buy(flight, price, callback) {
        let self = this;
        let payload = {
            flight: flight,
            price: price
        } 
        self.flightSuretyData.methods
            .buy(flight)
            .send({ from: self.owner, value: price}, (error, result) => {
                callback(error, payload);
            });
    }

    getCreditToPay(callback) {
        let self = this;
        self.flightSuretyData.methods.
        getCreditToPay().call({ from: self.owner}, (error, result) => {
            callback(error, result);
        });
    }

    pay(callback) {
        let self = this;
        self.flightSuretyData.methods.
        pay().call({ from: self.owner}, (error, result) => {
            callback(error, result);
        });
    }
}