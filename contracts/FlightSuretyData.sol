pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    // Account used to deploy contract
    address private contractOwner;           
    // Blocks all state changes throughout the contract if false                          
    bool private operational = true;                                    

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

    uint airlinesRegistered;
    uint flightsRegistered;
    struct Airline {
        uint registrationNumb;
        address airline;
        bool isFunded;
    }
    mapping(address => Airline) private airlines;

    struct PurchasedInsurance {
        uint256 purchaseAmount;
        address owner;
    }
    mapping(bytes32 => PurchasedInsurance) private insurance;


    struct Accounts {
        uint256 creditAmount;
    }
    mapping(address => Accounts) private account;

    struct NewAirline {
        uint votes;
    }
    mapping(address => NewAirline) private newAirline;

    uint256 insuranceBalance;

    address initialAirline;

    //Constructor
    constructor(address airlineAddress) public 
    {
        contractOwner = msg.sender;
        flightsRegistered = 0;
        airlinesRegistered = 0;
        initialAirline = airlineAddress;
        //registerAirline(airlineAddress);
        //contractOwner = appAddress;
    }
    

    //Function Modifiers
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;
    }

    //Modifier that requires the "ContractOwner" account to be the function caller
    modifier requireContractOwner()
    {
        //require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    //Modifier that checks if a flight exists
    modifier flightExists(bytes32 flight)
    {
        require(flights[flight].updatedTimestamp != 0, "Flight does not exist");
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

    //Utility Functions

    //Get operating status of contract
    function isOperational() public view returns(bool) 
    {
        return operational;
    }

    //Query whether flight is available
    function isFlightRegistered(bytes32 flight) external returns (bool)
    {
        if (flights[flight].updatedTimestamp == 0) {
            return false;
        }   
        return true;
    }

    //View insurance purchased for flight
    function viewInsurancePurchasedForFlight(bytes32 flight) view returns(uint256)
    {
        uint256 amount = insurance[flight].purchaseAmount;
        return amount;
    }

    //View Credited Account Balance
    function viewCreditedAccount() view returns(uint256)
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

    function returnInitialAirline() external returns(address)
    {
        return initialAirline;
    }

    function returnAirlineFunded(address airline) returns(bool)
    {
        bool isFunded = airlines[airline].isFunded;
        return isFunded;
    }

    function returnAirlinesRegistered() external returns(uint)
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

    function fundAirline() external payable requireEtherEqualTo10
    {
        airlines[msg.sender].isFunded = true;
        insuranceBalance = insuranceBalance.add(msg.value);
    }
    
    function isAirline(address airline) public returns(bool) 
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

    function registerFlight(bytes32 flight, uint timeStamp,uint8 statusCode,address airlineAddress) requireIsOperational external
    {
        Flight memory newFlight = Flight(true,statusCode,timeStamp,airlineAddress);
        flights[flight] = newFlight;
        flightsRegistered++;
    }

    // Buy insurance for a flight
    function buy(bytes32 flight) external payable flightExists(flight)
    {
        address buyerAddress = msg.sender;
        PurchasedInsurance memory newInsurance = PurchasedInsurance(msg.value,buyerAddress);
        insurance[flight] = newInsurance;
    }
    
    //Credits payouts to insurees
    function creditInsurees(bytes32 flight) external returns(uint256)                                  
    {
        address creditAddress = msg.sender;
        uint256 amount0 = insurance[flight].purchaseAmount.div(2);
        uint256 amount1 = insurance[flight].purchaseAmount;
        uint256 returnAmount = amount0.add(amount1);
        account[creditAddress].creditAmount = amount1.add(amount0).add(account[creditAddress].creditAmount);
        return account[creditAddress].creditAmount;
    }

    //Transfers eligible payout funds to insuree
    function pay()external payable
    {
        require(account[msg.sender].creditAmount > 0);
        uint256 prev = account[msg.sender].creditAmount;
        account[msg.sender].creditAmount = 0;
        insuranceBalance-= prev;
        msg.sender.transfer(prev);
    }

    //Initial funding for the insurance. Unless there are too many delayed flights resulting in insurance payouts, the contract should be self-sustaining
    function fund() public payable
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

    function test() public view returns (bool)
    {
        return false;
    }

    function test1() external
    {
        //flightsRegistered = flightsRegistered.add(50);
        flightsRegistered = 50;
    }

    function test2() external returns (uint256)
    {
        return flightsRegistered;
    }

    function test3() external returns (bool)
    {
        return true;
    }
    
}

