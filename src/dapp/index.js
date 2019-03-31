
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log("isOperational",error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });

        // User-submitted transaction
        DOM.elid('registerFlight').addEventListener('click', () => {
            let flight = DOM.elid('dropDownFlights_register').value;
            contract.generateFlight(flight,(error, result) => {
                console.log(result);
            });
        })    

        // User-submitted transaction
        DOM.elid('isRegistered').addEventListener('click', () => {
            let flight = DOM.elid('dropDownFlights_isRegistered').value;
            contract.isFlightRegistered(flight,(error, result) => {
                console.log(result);
            });
        })  
        
        // User-submitted transaction
        DOM.elid('fundAirline').addEventListener('click', () => {
            contract.fundAirline((error, result) => {
                console.log(result);
            });
        })  

        // User-submitted transaction
        DOM.elid('buyInsurance').addEventListener('click', () => {            
            let insuranceValue = DOM.elid('insuranceValue').value;
            let flight = DOM.elid('dropDownFlights_buyInsurance').value;            
            contract.buyInsurace(flight,insuranceValue,(error, result) => {
                console.log(result);
            });
        })  

        // User-submitted transaction
        DOM.elid('showCreditBalance').addEventListener('click', () => {
            contract.returnCreditAmount((error, result) => {
                console.log(result);
            });
        }) 

        // User-submitted transaction
        DOM.elid('payout').addEventListener('click', () => {
            contract.payoutInsurance((error, result) => {
                console.log(result);
            });
        }) 

        // User-submitted transaction
        DOM.elid('fetchFlightStatus').addEventListener('click', () => {
            let flight = DOM.elid('dropDownFlights_fetchFlight').value;   
            contract.fetchFlightStatus(flight,(error, result) => {
                console.log(result);
            });
        }) 

        // User-submitted transaction
        DOM.elid('showUserBalance').addEventListener('click', () => {
            contract.showUserBalance((error, result) => {
                console.log(result);
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







