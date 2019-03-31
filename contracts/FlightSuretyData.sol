pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    // Account used to deploy contract
    address private contractOwner;           
    // Blocks all state changes throughout the contract if false                          
    bool private operational = true;                                    

    //going to move this to app
    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;     
        address airline;
    }
    mapping(bytes32 => Flight) private flights;
    //going to move this to app

    uint airlinesRegistered;


    struct Airline {
        uint registrationNumb;
        address airline;
        bool isFunded;
    }
    mapping(address => Airline) private airlines;

    // struct PurchasedInsurance {
    //     uint256 purchaseAmount;
    //     address owner;
    // }
    // mapping(bytes32 => PurchasedInsurance) private insurance;


    struct Accounts {
        uint256 creditAmount;
    }
    mapping(address => Accounts) private account;

    struct NewAirline {
        uint votes;
    }
    mapping(address => NewAirline) private newAirline;

    // struct TempStruct {
    //     uint tempInt;
    // }
    // mapping(address => TempStruct) private tempMap;

    // struct TempStruct1 {
    //     address airline;
    //     uint statusCode;
    //     bool isRegistered;  
    // }
    // mapping(bytes32 => TempStruct1) private tempMap1;

    // struct TempStruct2 {
    //     bool isRegistered;
    //     uint8 statusCode;
    //     uint256 updatedTimestamp;     
    //     address airline;      
    // }
    // mapping(bytes32 => TempStruct2) private tempMap2;

    // struct TempStruct3 {
    //     address temp0;
    //     bool temp1;
    //     bool temp2;   
    //     bool temp3;  
    //     bool temp4;   
    //     bool temp5;        
    // }
    // mapping(bytes32 => TempStruct3) private tempMap3;

    uint256 insuranceBalance;

    address initialAirline;

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    //Constructor
    constructor(address airlineAddress) public 
    {
        contractOwner = msg.sender;
        airlinesRegistered = 0;
        initialAirline = airlineAddress;
        //registerAirline(airlineAddress);
        //contractOwner = appAddress;
    }
    

    //Function Modifiers
    modifier requireIsOperational() 
    {
        require(operational == true, "Contract is currently not operational");
        _;
    }

    //Modifier that requires the "ContractOwner" account to be the function caller
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    //Modifier that checks if a flight exists
    modifier flightExists(bytes32 flight)
    {
        require(flights[flight].updatedTimestamp != 0, "Flight does not exist");
        _;
    }

    modifier requireFlightDoesntExist(bytes32 flight)
    {
        require(flights[flight].updatedTimestamp == 0, "Flight already exists");
        _;
    }

    //Modifier that checks if a flight exists
    modifier isFundedBro()
    {
        require(airlines[msg.sender].isFunded == true, "Flight does not exist");
        _;
    }

    modifier hasVotes(address airlineAddress)
    {
        require(airlinesRegistered < 5 || newAirline[airlineAddress].votes >= airlinesRegistered.div(2), "Airline does not have enough votes");
        _;
    }

    //Modifier that checks if a submitted ether value is equal to 10 ether
    modifier requireEtherEqualTo10()
    {
        require(msg.value == 10 ether, "Ether required must be 10.");
        _;
    }

    modifier airlineIsNotPreviouslyFunded
    {
        require(airlines[msg.sender].isFunded != true, "Airline must not already be funded");
        _;
    }

    //Events

    event Test2(uint256 returnVal);

    //Utility Functions

    //Get operating status of contract
    function isOperational() public view returns(bool) 
    {
        return operational;
    }

    //Query whether flight is available
    function isFlightRegistered(bytes32 flight) view external returns (bool)
    {
        if (flights[flight].updatedTimestamp == 0) {
            return false;
        }   
        return true;
    }

    // function processFlightStatus(address airline, string flight, uint256 timestamp, uint8 statusCode) external
    // {
    //     //TODO
    //     //flights[flight].updatedTimestamp = 1;

    //     bytes32 temp = "fda";
    //     if (statusCode == STATUS_CODE_LATE_AIRLINE)
    //     {
    //         creditInsurees(temp);
    //     }
    // }

    //  function Time_call() returns (uint256){
    //     return now;
    // }

    //View insurance purchased for flight
    // function viewInsurancePurchasedForFlight(bytes32 flight) public view returns(uint256)
    // {
    //     uint256 amount = insurance[flight].purchaseAmount;
    //     return amount;
    // }

    //View Credited Account Balance
    function viewCreditedAccount() view public returns(uint256)
    {
        address creditAddress = msg.sender;
        uint256 amount = account[creditAddress].creditAmount;
        return amount;
    }

    //Sets contract operations on/off
    function setOperatingStatus(bool mode) external requireContractOwner 
    {
        operational = mode;
    }

    function returnInitialAirline() view external returns(address)
    {
        return initialAirline;
    }

    function returnAirlineFunded(address airline) view public returns(bool)
    {
        bool isFunded = airlines[airline].isFunded;
        return isFunded;
    }

    function returnAirlinesRegistered() view external returns(uint)
    {
        return airlinesRegistered;
    }
 
    //Smart Contract Functions

    //Add an airline to the registration queue
    //Can only be called from FlightSuretyApp contract
    function registerAirline(address airlineAddress) external isFundedBro hasVotes(airlineAddress)
    {
        airlinesRegistered = airlinesRegistered.add(1);
        Airline memory newAirline = Airline(airlinesRegistered,airlineAddress,false);
        airlines[airlineAddress] = newAirline;
    }

    function registerInitialAirline() external  
    {
        airlinesRegistered = airlinesRegistered.add(1);
        Airline memory newAirline = Airline(airlinesRegistered,initialAirline,false);
        airlines[initialAirline] = newAirline;
    }   

    function fundAirline() external payable airlineIsNotPreviouslyFunded
    {
        airlines[msg.sender].isFunded = true;
        insuranceBalance = insuranceBalance.add(msg.value);

    }
    
    function isAirline(address airline) view public returns(bool) 
    {
        // airlines[airline].registrationNumb = 4;
        // return false;
        bool isValidAirline = false;
        if (airlines[airline].airline != 0)
        {
            isValidAirline = true;
        }

        return isValidAirline;         
    }

    function castVoteForNewAirline(address inewAirline) public isFundedBro  //need modifier to mkae sure votes doesn't get cast twice
    {
        if (newAirline[inewAirline].votes == 0)
        {
            NewAirline memory newAirlineEntry = NewAirline(1);
            newAirline[inewAirline] = newAirlineEntry;
        }
        else 
        {
            newAirline[inewAirline].votes = newAirline[inewAirline].votes.add(1);
        }
    }

    function registerFlight(bytes32 flight, uint256 timeStamp, uint8 statusCode, address airlineAddress)
        requireIsOperational 
        //requireFlightDoesntExist(flight) 
        external //  
    //function registerFlight(bytes32 flight, uint timeStamp,address airlineAddress) external // requireIsOperational 
    {
        //uint256 time = Time_call();

        //works in test, not in dapp
        Flight memory newFlight = Flight(true,statusCode,0,contractOwner);
        flights[flight] = newFlight;
    }

    // // Buy insurance for a flight
    // function buy(bytes32 flight) external payable //flightExists(flight) newPurchase(flight)  //moving to app contract
    // {
    //     address buyerAddress = msg.sender;
    //     PurchasedInsurance memory newInsurance = PurchasedInsurance(msg.value,buyerAddress);
    //     insurance[flight] = newInsurance;
    // }
    
    //Credits payouts to insurees
    function creditInsurees(bytes32 flight) payable returns(uint256)                                  
    {
        // address creditAddress = msg.sender;
        // uint256 amount0 = insurance[flight].purchaseAmount.div(2);
        // uint256 amount1 = insurance[flight].purchaseAmount;
        // //uint256 returnAmount = amount0.add(amount1);
        // account[creditAddress].creditAmount = amount1.add(amount0).add(account[creditAddress].creditAmount);
        // return account[creditAddress].creditAmount;

        uint256 temp = 0;
        return 0;
    }

    //Transfers eligible payout funds to insuree
    // function pay()external payable
    // {
    //     require(account[msg.sender].creditAmount > 0);
    //     uint256 prev = account[msg.sender].creditAmount;
    //     account[msg.sender].creditAmount = 0;
    //     // insuranceBalance-= prev;
    //     msg.sender.transfer(prev);
    // }

    //Initial funding for the insurance. Unless there are too many delayed flights resulting in insurance payouts, the contract should be self-sustaining
    function fund() payable
    {
        insuranceBalance = msg.value;
    }

    function getFlightKey(address airline,string memory flight,uint256 timestamp) pure internal returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    //Fallback function for funding smart contract.
    function() external payable 
    {
        fund();
    }

    // function test() public pure returns (bool)
    // {
    //     return false;
    // }

    // function test1() external
    // {
    // }

    // function test2() view external returns (uint256)
    // {
    //     uint256 tempReturn = 46;
    //     return tempReturn;
    // }

    // function test3() pure external returns (bool)
    // {
    //     return true;
    // }
    
}

