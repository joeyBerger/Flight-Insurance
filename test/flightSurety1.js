
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

  it('(airlines) can vote on a new airline, and that airline can be registered', async () => {

  // ARRANGE
  let newAirline = [accounts[5],accounts[6],accounts[7],accounts[8]];
  let votedAirline = accounts[9];

  let amount = 10; 
  amount = web3.utils.toWei(amount.toString(), 'ether');

  // ACT
  await config.flightSuretyData.fundAirline({from: config.firstAirline, value: amount})

  // ACT
  for (var i = 0; i < newAirline.length; i++)
  {
    await config.flightSuretyData.registerAirline(newAirline[i], {from: config.firstAirline});
    await config.flightSuretyData.fundAirline({from: newAirline[i], value: amount}) 
    await config.flightSuretyData.castVoteForNewAirline(votedAirline,{from: newAirline[i]}) 
  }
  await config.flightSuretyData.registerAirline(votedAirline, {from: config.firstAirline});
  let result = await config.flightSuretyData.isAirline.call(votedAirline); 
  // ASSERT
  assert.equal(result, true, "Airline that has been provided more than half of the votes of available airlines should be allowed to register as a new airline.");
  });

  it('(airlines) that recieve less than half of votes from existing airlines cannot registrer as an airline', async () => {

    // ARRANGE
    let newAirline = accounts[5];
    let votedAirline = accounts[10];
  
    // ACT
    await config.flightSuretyData.castVoteForNewAirline(votedAirline,{from: newAirline}) 
    
    try {
        await config.flightSuretyApp.registerAirline(votedAirline, {from: config.firstAirline});
    }
    catch(e) {
        
    }
    
    let result = await config.flightSuretyData.isAirline.call(votedAirline); 
    // ASSERT
    assert.equal(result, false, "Airline that has been provided more less than half of the votes of available airlines should not be allowed to register as a new airline.");
    });

  it('(airline) cannot fund itself if ether value is less than 10', async () => {

    // ARRANGE
    let amount = .9; 
    amount = web3.utils.toWei(amount.toString(), 'ether');

    let result = true;

    fundedAirline = accounts[9];
    
    // ACT  
    try {
      await config.flightSuretyApp.fundAirline({from: fundedAirline, value: amount})
    }
    catch(e) {
      result = false;
    }

    assert.equal(result, false, "Airline cannot fund itself if the ehter amount is less than 10");
    });
});
