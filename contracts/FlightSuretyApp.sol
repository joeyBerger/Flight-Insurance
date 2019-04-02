pragma solidity ^ 0.4 .25;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyApp {
    using SafeMath
    for uint256;

    //Data Variables
    FlightSuretyData flightSuretyData;

    // Flight status codes
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    // Account used to deploy contract
    address private contractOwner;

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
        address[] insuredAddresses;
        mapping(bytes32 => PurchasedInsurance) insurance;
    }
    mapping(bytes32 => Flight) private flights;

    struct PurchasedInsurance {
        uint256 purchaseAmount;
        address owner;
    }

    struct Accounts {
        uint256 creditAmount;
    }
    mapping(address => Accounts) account;

    bool isOperationalFlag;

    //Function Modifiers

    // // Modify to call data contract's status
    modifier requireIsOperational() {
        require(isOperationalFlag == true, "Contract is currently not operational");
        _;
    }

    //Modifier to make sure flight is registered
    modifier requireFlightRegistered(bytes32 flight) {
        bool registered = isFlightRegistered(flight);
        require(registered == true, "Flight must be registered in order to purchase insurance");
        _;
    }

    //Modifier to make sure flight is not registered
    modifier requireFlightNotRegistered(bytes32 flight) {
        bool registered = isFlightRegistered(flight);
        require(registered == false, "Flight must not already be registered");
        _;
    }

    //Modifier that purchaser has not already purchased insurance
    modifier requireNewPurchase(bytes32 flight) {
        require(flights[flight].insurance[flight].owner == address(0), "Flight insurance has already been purchased by buyer");
        _;
    }

    //Modifier that checks if a submitted ether value is greater than 0
    modifier requireEtherMoreThanZero() {
        require(msg.value > 0 ether, "Ether required must be greater than zero.");
        _;
    }

    //Modifier that checks if a submitted ether value is less or equal to 1
    modifier requireEtherNoMoreThanOneEther() {
        require(msg.value <= 1 ether, "Ether required must be less or equal to 1.");
        _;
    }

    //Modifier that checks if a submitted ether value is equal to 10 ether
    modifier requireEtherEqualTo10() {
        require(msg.value == 10 ether, "Ether required must be 10.");
        _;
    }

    //Modifier that makes sure status code is unknown
    modifier statusCodeIsUnknown(bytes32 flight) {
        require(flights[flight].statusCode == STATUS_CODE_UNKNOWN, "Status code must be unknown");
        _;
    }

    // //Modifier that checks if registering airline is indeed the initial airline
    // modifier requiReregisteringAirlineIsInitial() {
    //     //require(msg.value <= 1 ether, "Ether required must be less or equal to 1.");
    //     _;
    // }

    //Constructor
    constructor(address dataContract) public {
        contractOwner = msg.sender;
        //airlinesRegistered = 0;
        flightSuretyData = FlightSuretyData(dataContract);
        flightSuretyData.registerInitialAirline();
        isOperationalFlag = true;
    }

    //Utility Functions
    function isOperational() public view returns(bool) {
        return isOperationalFlag;
    }

    //Smart Contract Functions

    //Add an airline to the registration queue
    function registerAirline(address airline) public requireIsOperational {
        flightSuretyData.registerAirline(airline);
    }

    function fundAirline() public payable requireEtherEqualTo10 {
        flightSuretyData.fundAirline();
    }

    //Register a future flight for insuring.
    function registerFlight(bytes32 flight, uint256 timeStamp, address airlineAddress) public requireIsOperational requireFlightNotRegistered(flight) {
        //TODO: track airline with flight
        Flight memory newFlight = Flight(true, 0, timeStamp, contractOwner, new address[](0));
        flights[flight] = newFlight;
    }

    function isFlightRegistered(bytes32 flight) public view returns(bool) {
        bool isRegistered = flights[flight].updatedTimestamp != 0;
        return isRegistered;
    }

    function buy(bytes32 flight) public payable requireIsOperational requireFlightRegistered(flight) requireNewPurchase(flight) requireEtherMoreThanZero requireEtherNoMoreThanOneEther {
        address buyerAddress = msg.sender;
        PurchasedInsurance memory newInsurance = PurchasedInsurance(msg.value, buyerAddress);
        flights[flight].insurance[flight] = newInsurance;
        flights[flight].insuredAddresses.push(buyerAddress);
    }

    //function creditInsurees(bytes32 flight, address insuredAddress) payable returns(uint256) {
    function creditInsurees(bytes32 flight, address insuredAddress) returns(uint256) {
        //multiply the purchase amount by 1.5
        uint256 returnAmount = flights[flight].insurance[flight].purchaseAmount.mul(3).div(2);
        account[insuredAddress].creditAmount = returnAmount.add(account[insuredAddress].creditAmount);
        return returnAmount;
    }

    function returnedPurchasedAmount(bytes32 flight) public view returns(uint256) {
        return flights[flight].insurance[flight].purchaseAmount;
    }

    function returnCreditAmount() public view returns(uint256) {
        return account[msg.sender].creditAmount;
    }

    function withdrawl() public requireIsOperational {
        require(account[msg.sender].creditAmount > 0);
        uint256 prev = account[msg.sender].creditAmount;
        account[msg.sender].creditAmount = 0;
        msg.sender.transfer(prev);
    }

    //Called after oracle has updated flight status
    function processFlightStatus(address airline, bytes32 flight, uint256 timestamp, uint8 statusCode) internal statusCodeIsUnknown(flight) {
        flights[flight].statusCode = statusCode;
        if (statusCode == STATUS_CODE_LATE_AIRLINE) {
            for (uint i = 0; i < flights[flight].insuredAddresses.length; i++) {
                creditInsurees(flight, flights[flight].insuredAddresses[i]);
            }
        }
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(address airline, string flight, uint256 timestamp) external {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
            requester: msg.sender,
            isOpen: true
        });

        emit OracleRequest(index, airline, flight, timestamp);
    }


    // region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester; // Account that requested status
        bool isOpen; // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses; // Mapping key is the status code reported
        // This lets us group responses and identify
        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event OracleRegistered();

    event FlightStatusInfo(address airline, bytes32 flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, bytes32 flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);

    event CreditAccount(bytes32 flight, address insuredAddress);

    // Register an oracle with the contract
    function registerOracle() external payable {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
            isRegistered: true,
            indexes: indexes
        });

        emit OracleRegistered();
    }

    function getMyIndexes() view external returns(uint8[3]) {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(uint8 index, address airline, bytes32 flight, uint256 timestamp, uint8 statusCode) external {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");

        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        //require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }

    function getFlightKey(address airline, string flight, uint256 timestamp) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address iaccount) internal returns(uint8[3]) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(iaccount);

        indexes[1] = indexes[0];
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(iaccount);
        }

        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(iaccount);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address iaccount) internal returns(uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), iaccount))) % maxValue);

        if (nonce > 250) {
            nonce = 0; // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    // endregion
}

//Data Interface
contract FlightSuretyData {
    function registerAirline(address airlineAddress) external;

    function registerInitialAirline() external;

    function returnInitialAirline() external returns(address);

    function fundAirline() external payable;
}