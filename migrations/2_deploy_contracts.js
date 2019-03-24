const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');

module.exports = function(deployer) {

    let firstAirline = '0xf17f52151EbEF6C7334FAD080c5704D77216b732';
    //{one: 1, two: 2}  // https://github.com/trufflesuite/truffle/issues/446
    deployer.deploy(FlightSuretyData,firstAirline)
    .then(() => {
        //deployer.link(FlightSuretyData, FlightSuretyApp);
        //console.log("address",FlightSuretyData.address);
        return deployer.deploy(FlightSuretyApp,FlightSuretyData.address)
                .then(() => {
                    
                    let config = {
                        localhost: {
                            url: 'http://localhost:8545',
                            dataAddress: FlightSuretyData.address,
                            appAddress: FlightSuretyApp.address
                        }
                    }
                    fs.writeFileSync(__dirname + '/../src/dapp/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
                    fs.writeFileSync(__dirname + '/../src/server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
                });
    });
}