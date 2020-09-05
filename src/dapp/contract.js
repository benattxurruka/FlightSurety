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

    async initialize(callback) {
        if (window.ethereum) {
            try {
                this.web3 = new Web3(window.ethereum);
                // Request account access
                await window.ethereum.enable();
            } catch (error) {
                // User denied account access...
                console.error("User denied account access")
            }
        }
        if (typeof this.web3 == "undefined") {
            this.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:8545"));
            console.log("local ganache provider");
        }
        

        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];

            this.accounts = accts;
            console.log(this.accounts);

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

    async refreshAccounts(callback){
        this.web3.eth.getAccounts((error, accts) => {

            this.accounts = accts;

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(airline, flight, callback) {
        let self = this;
        let payload = {
            airline: airline,
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.accounts[0]}, (error, result) => {
                callback(error, payload);
            });
    }

    registerAirline(address, name, sender, callback) {
        let self = this;
        let payload = {
            airlineAddress: address,
            name: name,
            sender: sender
        }
        self.flightSuretyData.methods
            .registerAirline(payload.airlineAddress, payload.name)
            .send({ from: payload.sender,
                gas: 5000000,
                gasPrice: 20000000
            }, (error, result) => {
                callback(error, payload);
            });
    }

    fund(funds, callback) {
        let self = this;
        let value = this.web3.utils.toWei(funds.toString(), "ether");
        let payload = {
            funds: value
        } 
        console.log(payload);
        self.flightSuretyData.methods
            .fund()
            .send({ from: self.owner, value: value}, (error, result) => {
                callback(error, payload);
            });
    }

    registerFlight(flight, destination, callback) {
        let self = this;
        let payload = {
            flight: flight,
            destination: destination,
            timestamp: Math.floor(Date.now() / 1000)
        }
        console.log(payload);
        self.flightSuretyApp.methods
            .registerFlight(payload.flight, payload.destination, payload.timestamp)
            .send({ from: self.accounts[0],
                gas: 5000000,
                gasPrice: 20000000}, (error, result) => {
                callback(error, payload);
            });
    }

    buy(flight, price, callback) {
        let self = this;
        let priceInWei = this.web3.utils.toWei(price.toString(), "ether");
        let payload = {
            flight: flight,
            price: priceInWei,
            passenger: self.accounts[0]
        } 
        console.log(payload);
        self.flightSuretyData.methods
            .buy(flight)
            .send({ from: self.accounts[0], value: price,
                gas: 500000,
                gasPrice: 20000000}, (error, result) => {
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