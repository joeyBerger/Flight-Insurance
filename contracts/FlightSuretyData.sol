pragma solidity ^ 0.4 .25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath
    for uint256;

    // Account used to deploy contract
    address private contractOwner;
    // Blocks all state changes throughout the contract if false                          
    bool private operational = true;

    uint airlinesRegistered;

    struct Airline {
        uint registrationNumb;
        address airline;
        bool isFunded;
    }
    mapping(address => Airline) private airlines;

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

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    //Constructor
    constructor(address airlineAddress) public {
        contractOwner = msg.sender;
        airlinesRegistered = 0;
        initialAirline = airlineAddress;
    }


    //Function Modifiers
    modifier requireIsOperational() {
        require(operational == true, "Contract is currently not operational");
        _;
    }

    //Modifier that requires the "ContractOwner" account to be the function caller
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    //Modifier that checks if a flight exists
    modifier isAirlineFunded() {
        require(airlines[msg.sender].isFunded == true, "Flight does not exist");
        _;
    }

    modifier hasVotes(address airlineAddress) {
        require(airlinesRegistered < 5 || newAirline[airlineAddress].votes >= airlinesRegistered.div(2), "Airline does not have enough votes");
        _;
    }

    //Modifier that checks if a submitted ether value is equal to 10 ether
    modifier requireEtherEqualTo10() {
        require(msg.value == 10 ether, "Ether required must be 10.");
        _;
    }

    modifier airlineIsNotPreviouslyFunded {
        require(airlines[msg.sender].isFunded != true, "Airline must not already be funded");
        _;
    }

    //Events

    event Test2(uint256 returnVal);

    //Utility Functions

    //Get operating status of contract
    function isOperational() public view returns(bool) {
        return operational;
    }

    //View Credited Account Balance
    function viewCreditedAccount() view public returns(uint256) {
        address creditAddress = msg.sender;
        uint256 amount = account[creditAddress].creditAmount;
        return amount;
    }

    //Sets contract operations on/off
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    //Returns initial registered airline
    function returnInitialAirline() view external returns(address) {
        return initialAirline;
    }

    //Returns whther given airline is funded
    function returnAirlineFunded(address airline) view public returns(bool) {
        bool isFunded = airlines[airline].isFunded;
        return isFunded;
    }

    //Smart Contract Functions

    //Add an airline to the registration queue
    //Can only be called from FlightSuretyApp contract
    function registerAirline(address airlineAddress) external isAirlineFunded hasVotes(airlineAddress) requireIsOperational {
        airlinesRegistered = airlinesRegistered.add(1);
        Airline memory newRegisteredAirline = Airline(airlinesRegistered, airlineAddress, false);
        airlines[airlineAddress] = newRegisteredAirline;
    }

    //Registers initial airline
    function registerInitialAirline() external requireIsOperational {
        airlinesRegistered = airlinesRegistered.add(1);
        Airline memory registeredAirline = Airline(airlinesRegistered, initialAirline, false);
        airlines[initialAirline] = registeredAirline;
    }

    //Funds airline
    function fundAirline() external payable airlineIsNotPreviouslyFunded requireIsOperational {
        airlines[msg.sender].isFunded = true;
        insuranceBalance = insuranceBalance.add(msg.value);

    }

    //Returns whether airline is valid
    function isAirline(address airline) view public returns(bool) {
        bool isValidAirline = false;
        if (airlines[airline].airline != 0) {
            isValidAirline = true;
        }
        return isValidAirline;
    }

    //Cast vote for airline
    function castVoteForNewAirline(address inewAirline) public isAirlineFunded requireIsOperational{
        if (newAirline[inewAirline].votes == 0) {
            NewAirline memory newAirlineEntry = NewAirline(1);
            newAirline[inewAirline] = newAirlineEntry;
        } else {
            newAirline[inewAirline].votes = newAirline[inewAirline].votes.add(1);
        }
    }

    //Initial funding for the insurance. Unless there are too many delayed flights resulting in insurance payouts, the contract should be self-sustaining
    function fund() public payable {
        insuranceBalance = msg.value;
    }

    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    //Fallback function for funding smart contract.
    function() external payable {
        fund();
    }
}