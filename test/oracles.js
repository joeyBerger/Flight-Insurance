var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
const truffleAssert = require('truffle-assertions');

contract('Oracles', async (accounts) => {

    const TEST_ORACLES_COUNT = 20; //20;
    // Watch contract events
    const STATUS_CODE_UNKNOWN = 0;
    const STATUS_CODE_ON_TIME = 10;
    const STATUS_CODE_LATE_AIRLINE = 20;
    const STATUS_CODE_LATE_WEATHER = 30;
    const STATUS_CODE_LATE_TECHNICAL = 40;
    const STATUS_CODE_LATE_OTHER = 50;

    let statusArr = [STATUS_CODE_UNKNOWN, STATUS_CODE_ON_TIME, STATUS_CODE_LATE_WEATHER, STATUS_CODE_LATE_TECHNICAL, STATUS_CODE_LATE_OTHER, STATUS_CODE_LATE_AIRLINE, STATUS_CODE_LATE_AIRLINE, STATUS_CODE_LATE_AIRLINE, STATUS_CODE_LATE_AIRLINE, STATUS_CODE_LATE_AIRLINE];
    let statusDict = [];
    statusDict[STATUS_CODE_UNKNOWN] = "STATUS_CODE_UNKNOWN";
    statusDict[STATUS_CODE_ON_TIME] = "STATUS_CODE_ON_TIME";
    statusDict[STATUS_CODE_LATE_AIRLINE] = "STATUS_CODE_LATE_AIRLINE";
    statusDict[STATUS_CODE_LATE_WEATHER] = "STATUS_CODE_LATE_WEATHER";
    statusDict[STATUS_CODE_LATE_TECHNICAL] = "STATUS_CODE_LATE_TECHNICAL";
    statusDict[STATUS_CODE_LATE_OTHER] = "STATUS_CODE_LATE_OTHER";

    // console.log(statusArr.length, statusArr[9],statusDict[0],statusDict["STATUS_CODE_UNKNOWN"]);
    console.log(statusDict[STATUS_CODE_UNKNOWN]);

    var config;
    before('setup contract', async () => {
        console.log("STATUS_CODE_UNKNOWN", STATUS_CODE_UNKNOWN);
        config = await Test.Config(accounts);

        // Watch contract events
        //const ON_TIME = 10;
        //let events = config.flightSuretyApp.allEvents();
        // events.watch((error, result) => {
        //   if (result.event === 'OracleRequest') {
        //     console.log(`\n\nOracle Requested: index: ${result.args.index.toNumber()}, flight:  ${result.args.flight}, timestamp: ${result.args.timestamp.toNumber()}`);
        //   } else {
        //     console.log(`\n\nFlight Status Available: flight: ${result.args.flight}, timestamp: ${result.args.timestamp.toNumber()}, status: ${result.args.status.toNumber() == ON_TIME ? 'ON TIME' : 'DELAYED'}, verified: ${result.args.verified ? 'VERIFIED' : 'UNVERIFIED'}`);
        //   }
        // });
    });

    // it('can register oracles', async () => {

    //     // ARRANGE
    //     let fee = await config.flightSuretyApp.REGISTRATION_FEE.call();
    //     let flight = 'ND1309'; // Course number
    //     let timestamp = Math.floor(Date.now() / 1000);

    //     // Submit a request for oracles to get status information for a flight
    //     let tx = await config.flightSuretyApp.fetchFlightStatus(config.firstAirline, flight, timestamp);
    //     truffleAssert.eventEmitted(tx, 'OracleRequest', (ev) => {
    //         return ev.flight = flight;
    //     });
    // });

    it('can register oracles', async () => {

        // ARRANGE
        let fee = await config.flightSuretyApp.REGISTRATION_FEE.call();

        // ACT
        for (let a = 1; a < TEST_ORACLES_COUNT; a++) {
            await config.flightSuretyApp.registerOracle({
                from: accounts[a],
                value: fee
            });
            let result = await config.flightSuretyApp.getMyIndexes.call({
                from: accounts[a]
            });
            console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
        }
    });

    it('can request flight status', async () => {

        // ARRANGE
        let flight = 'ND1309'; // Course number
        let timestamp = Math.floor(Date.now() / 1000);

        // ACT
        // Submit a request for oracles to get status information for a flight
        await config.flightSuretyApp.fetchFlightStatus(config.firstAirline, flight, timestamp);        

        // Since the Index assigned to each test account is opaque by design
        // loop through all the accounts and for each account, all its Indexes (indices?)
        // and submit a response. The contract will reject a submission if it was
        // not requested so while sub-optimal, it's a good test of that feature
        for (let a = 1; a < TEST_ORACLES_COUNT; a++) {
            // Get oracle information
            let oracleIndexes = await config.flightSuretyApp.getMyIndexes.call({
                from: accounts[a]
            });
            let statusInd = Math.floor(Math.random() * 10);
            for (let idx = 0; idx < 3; idx++) {
                try {
                    // Submit a response...it will only be accepted if there is an Index match         
                    let tx = await config.flightSuretyApp.submitOracleResponse(oracleIndexes[idx].toNumber(), config.firstAirline, flight, timestamp, statusArr[statusInd], {
                        from: accounts[a]
                    });
                    try {
                        truffleAssert.eventEmitted(tx, 'FlightStatusInfo', (ev) => {
                            console.log("Flight Status Available: " + ev.flight + ", " + statusDict[parseInt(ev.status.toString())]);
                            return true;
                        });
                    } catch (e) {}

                    //let flightStatus = await config.flightSuretyApp.fetchFlightStatus(config.firstAirline,flight,timestamp);
                    // console.log(idx,oracleIndexes[idx],flight,timestamp,flightStatus);
                } catch (e) {
                    // Enable this when debugging
                    console.log('\nError', idx, oracleIndexes[idx].toNumber(), flight, timestamp, e);
                }
            }
        }
    });
});