
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })

        // User-submitted transaction
        DOM.elid('register-airline').addEventListener('click', (e) => {
            e.preventDefault();
            let address = DOM.elid('airline-address').value;
            let name = DOM.elid('airline-name').value;
            console.log('address: '+address+'. Name: '+name);
            // Write transaction
            contract.registerAirline(address, name, (error, result) => {
                display('Airlines', 'Register a new airline', [ { label: 'Register Airline', error: error, value: result.address + ' ' + result.name} ]);
            });
        })
        
        // User-submitted transaction
        DOM.elid('fund').addEventListener('click', () => {
            // e.preventDefault();
            let funds = DOM.elid('funds').value;
            // Write transaction
            contract.fund(funds, (error, result) => {
                display('Funds', 'Fund yourself', [ { label: 'Fund added to airline', error: error, value: result.funds} ]);
            });
        })

        // User-submitted transaction
        DOM.elid('register-flight').addEventListener('click', () => {
            let flight = DOM.elid('new-flight-number').value;
            let destination = DOM.elid('new-flight-destination').value;
            // Write transaction
            contract.registerFlight(flight, destination, (error, result) => {
                display('New Flights', 'Register a new flight', [ { label: 'New Flight info', error: error, value: result.flight + ' ' + result.destination} ]);
            });
        })

        // User-submitted transaction
        DOM.elid('buy-insurance').addEventListener('click', () => {
            let flight = DOM.elid('insurance-flight').value;
            let price = DOM.elid('insurance-price').value;
            // Write transaction
            contract.buy(flight, price, (error, result) => {
                display('Buy insurance', 'Buy a new flight insurance', [ { label: 'Bought insurance info', error: error, value: result.flight} ]);
            });
        })

        // User-submitted transaction
        DOM.elid('check-credit').addEventListener('click', () => {
            // Write transaction
            contract.getCreditToPay((error, result) => {
                if(error){
                    console.log(error);
                    let creditDisplay = DOM.elid("credit-ammount");
                    creditDisplay.value = "Error happened while getting your credit";
                } else {
                    let creditDisplay = DOM.elid("credit-ammount");
                    creditDisplay.value = result+" ethers";
                }
            });
        })

        // User-submitted transaction
        DOM.elid('claim-credit').addEventListener('click', () => {
            // Write transaction
            contract.pay((error, result) => {
                if(error){
                    console.log(error);
                    let creditDisplay = DOM.elid("credit-ammount");
                } else {
                    let creditDisplay = DOM.elid("credit-ammount");
                    creditDisplay.value = "0 ethers";
                    alert("Successfully withdrawed!");
                }
            });
        })
        
    });
    

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







