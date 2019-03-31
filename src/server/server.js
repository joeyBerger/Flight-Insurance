import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';

let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

let oracleAdresses = [];

const STATUS_CODE_UNKNOWN = 0;
const STATUS_CODE_ON_TIME = 10;
const STATUS_CODE_LATE_AIRLINE = 20;
const STATUS_CODE_LATE_WEATHER = 30;
const STATUS_CODE_LATE_TECHNICAL = 40;
const STATUS_CODE_LATE_OTHER = 50;

//forcing status code to STATUS_CODE_LATE_AIRLINE, to force a credit to account

const registerInitialOracles = () => new Promise((resolve, reject) => {
  web3.eth.getAccounts(
      (error, result) => {
          if (error) {
              console.error('Error encountered while registering oracles')
              reject(error)
          } else {
              resolve(result)
          }
      }).then(function(result) {
      oracleAdresses = result;
      for(var i = 20; i < 40; i++){
        flightSuretyApp.methods
        .registerOracle()
        .send({
            from: oracleAdresses[i],
            value: web3.utils.toWei('1', 'ether'),
            gas: 1000000
        }, (error, result) => {
            if (error) {
                console.error('Error encountered while registering oracles')
                reject(error)
            } else {
                resolve(result)
            }
       
          })
      }
  })
})

const submitOracleResponse = (event) => new Promise((resolve, reject) => {
  let validOracles = [];
  let count = 20;
  let oracleResponseSubmitted = false;
  for (var i = 20; i < 40; i++) {
      flightSuretyApp.methods
          .getMyIndexes()
          .call({
              from: oracleAdresses[i],
              gas: 1000000
          }, (error, result) => {
              if (error) {
                  console.error('Error encountered while querying oracle indices')
                  reject(error)
              } else {
                  console.log(result, count);
                  if (validOracles.length < 3) {
                      for (var j = 0; j < 3; j++) {
                          if (result[j] === event.returnValues.index) {
                              validOracles.push(count);
                              break;
                          }
                      }
                  }
                  count++;
                  resolve(result)
              }
          }).then(function() {
              if (validOracles.length === 3 && !oracleResponseSubmitted) {
                  oracleResponseSubmitted = true;
                  for (var k = 0; k < validOracles.length; k++) {
                      flightSuretyApp.methods
                          .submitOracleResponse(event.returnValues.index, event.returnValues.airline, web3.utils.fromAscii(event.returnValues.flight), event.returnValues.timestamp, STATUS_CODE_LATE_AIRLINE)
                          .send({
                              from: oracleAdresses[validOracles[k]],
                              gas: 1000000
                          }, (error, result) => {
                              if (error) {
                                  console.error('Error while submitting oracle response')
                                  reject(error)
                              } else {
                                  console.log(result);
                                  resolve(result)
                              }
                          })
                  }
              }
          })
  }
})

registerInitialOracles();

flightSuretyApp.events.OracleRegistered({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log("Oracle registered at",event.transactionHash);
  //console.log(event)
});

flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log(error)
    // console.log("got event",event)
    console.log("Oracle Request event logged");
    submitOracleResponse(event);
});

flightSuretyApp.events.OracleReport({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log("got event",event)
});

flightSuretyApp.events.FlightStatusInfo({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log("got event",event)
});

flightSuretyApp.events.CreditAccount({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log("got credit account!",event);
  
});

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;


