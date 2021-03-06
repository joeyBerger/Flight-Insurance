
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    let fundAmount = 1;
    fundAmount = web3.utils.toWei(fundAmount.toString(), 'ether');
    config.flightSuretyData.fund({value:fundAmount});
  });
  
  it(`(multiparty) has correct initial isOperational() value`, async function () {
    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");
  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, {from: config.testAddresses[2]});
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSuretyData.isOperationalFake(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);
  });

  it('(airline) can register an Airline using registerAirline() once funded', async () => {

  // ARRANGE
  let newAirline = accounts[4];

  let amount = 10; 
  amount = web3.utils.toWei(amount.toString(), 'ether');

  // ACT
  await config.flightSuretyData.fundAirline({from: config.firstAirline, value: amount}) 

  // ACT
  try {
      await config.flightSuretyData.registerAirline(newAirline, {from: config.firstAirline});
  }
  catch(e) {

  }
  let result = await config.flightSuretyData.isAirline.call(newAirline); 

  // ASSERT
  assert.equal(result, true, "Airline should be able to register another airline if it has provided funding");
  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[9];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");
  }); 

  it('(client) can register a Flight using registerFlight()', async () => {
      
      // ARRANGE
      let newAirline = accounts[2];
      let timeStamp = Date.now();
      let flightName = web3.utils.fromAscii("SX123");

      // ACT
      try {
          await config.flightSuretyApp.registerFlight(flightName,timeStamp,newAirline);
      }
      catch(e) {

      }

      let fakeFlightName = web3.utils.fromAscii("20160528");
      let result0 = await config.flightSuretyApp.isFlightRegistered.call(flightName); 
      let result1 = await config.flightSuretyApp.isFlightRegistered.call(fakeFlightName); 

      // ASSERT
      assert.equal(result0, true, "Flight that exists is showing as not registered");
      assert.equal(result1, false, "Flight that does not exist is showing indeed registered");
    });


  it('(client) can buy insurance using buy()', async () => {    
    // ARRANGE
    let newAirline = accounts[2];
    let timeStamp = Date.now();
    let flightName = web3.utils.fromAscii("SX123");

    let buyer = accounts[3];
    let amount = 1;
    let insuranceValue = web3.utils.toWei(amount.toString(), 'ether');

    // ACT
    await config.flightSuretyApp.buy(flightName,{from: buyer, value: insuranceValue});

    let purchaseAmount  = await config.flightSuretyApp.returnedPurchasedAmount(flightName);
    purchaseAmount = purchaseAmount.toString()

    assert.equal(insuranceValue, purchaseAmount, "Insurance bought unsuccessfully"); 
  });
});
