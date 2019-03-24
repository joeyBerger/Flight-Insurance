pragma solidity ^0.4.25;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; 

    //Data Variables

    FlightSuretyData flightSuretyData;

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    // Account used to deploy contract
    address private contractOwner;         

    //Function Modifiers

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    
    
    
    //TODO

    // Modify to call data contract's status
    modifier requireIsOperational() 
    {         
        require(true == true, "Contract is currently not operational");  
        _;
    }

    //Modifier that requires the "ContractOwner" account to be the function caller
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireFlightRegistered(bytes32 flight)
    {
        bool registered = isFlightRegistered(flight);
        require(registered == true, "Flight must be registered in order to purchase insurance");
        _;
    }

    //Modifier that checks if a submitted ether value is greater than 0
    modifier requireEtherMoreThanZero()
    {
        require(msg.value > 0 ether, "Ether required must be greater than zero.");
        _;
    }

    //Modifier that checks if a submitted ether value is less or equal to 1
    modifier requireEtherNoMoreThanOneEther()
    {
        require(msg.value <= 1 ether, "Ether required must be less or equal to 1.");
        _;
    }

    //Modifier that checks if a submitted ether value is equal to 10 ether
    modifier requireEtherEqualTo10()
    {
        require(msg.value == 10 ether, "Ether required must be 10.");
        _;
    }

    //Modifier that checks if registering airline is indeed the initial airline
    modifier requiReregisteringAirlineIsInitial()
    {
        //require(msg.value <= 1 ether, "Ether required must be less or equal to 1.");
        _;
    }

    // function isFlightRegistered(bytes32 flight) public view returns (bool)
    // {
    //     bool registered = flightSuretyData.isFlightRegistered(flight);
    //     return registered;
    // }

    //Constructor
    constructor(address dataContract) public 
    {
        contractOwner = msg.sender;
        //airlinesRegistered = 0;
        flightSuretyData = FlightSuretyData(dataContract);
        flightSuretyData.registerInitialAirline();
    }

    //Utility Functions

    function isOperational() public pure requireIsOperational returns(bool) 
    {
        return false;
    }

    //Smart Contract Functions

    //Add an airline to the registration queue
    function registerAirline(address airline) public returns(bool success, uint256 votes)
    {
        uint airlinesRegistered = flightSuretyData.returnAirlinesRegistered();

        if (airlinesRegistered < 5)
        {
            // address initialAirline = flightSuretyData.returnInitialAirline();
            // if (initialAirline != msg.sender)
            // {
            //     return(false,0);
            // }
            flightSuretyData.registerAirline(airline);
            return(true,0);
        }
        return (success, 0);
    }

    function fundAirline() public payable requireEtherEqualTo10
    {
        flightSuretyData.fundAirline();
    }

    //Register a future flight for insuring.
    function registerFlight(bytes32 flight, uint timeStamp, address airlineAddress) public
    {
        // Flight memory newFlight = Flight(true,STATUS_CODE_UNKNOWN,timeStamp,airlineAddress);
        // flights[flight] = newFlight;
        flightSuretyData.registerFlight(flight,timeStamp,STATUS_CODE_UNKNOWN,airlineAddress);
    }

    function isFlightRegistered(bytes32 flight) public view returns (bool)
    {
        bool registered = flightSuretyData.isFlightRegistered(flight);
        return registered;
    }

    function buy(bytes32 flight) public requireFlightRegistered(flight) requireEtherMoreThanZero requireEtherNoMoreThanOneEther
    {
        flightSuretyData.buy(flight);
    }

    function test() public view returns (bool)
    {
        return true;
    }

    function test1() public
    {
        flightSuretyData.test1();
    }

    function test2() public returns (uint256)
    {
        uint256 returnVal = flightSuretyData.test2();
        return returnVal;
    }

    function test3() public view returns (bool)
    {
        bool val = flightSuretyData.test3();
        return val;
        //return true;
    }

    // function simpleTest() public returns(bool) 
    // {
    //     return false;
    // }

    //Called after oracle has updated flight status
    function processFlightStatus(address airline, string memory flight, uint256 timestamp, uint8 statusCode) internal pure
    {
        //TODO
    //         struct Flight {
    //     bool isRegistered;
    //     uint8 statusCode;
    //     uint256 updatedTimestamp;        
    //     address airline;
    // }
    // mapping(bytes32 => Flight) private flights;        
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(address airline,string flight,uint256 timestamp) external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({requester: msg.sender,isOpen: true});

        emit OracleRequest(index, airline, flight, timestamp);
    } 


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;  //3;  TODO: Should be 3


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);

    // Register an oracle with the contract
    function registerOracle() external payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
    }

    function getMyIndexes() view external returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(uint8 index, address airline, string flight, uint256 timestamp, uint8 statusCode) external
    {
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

    function getFlightKey(address airline,string flight,uint256 timestamp )pure internal returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account) internal returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address account) internal returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion
}   

//Data Interface
contract FlightSuretyData {
    //function registerAirline() external;
    function registerFlight(bytes32 flight, uint timeStamp, uint8 statusCode, address airlineAddress) external;
    function isFlightRegistered(bytes32 flight) external returns (bool);
    function buy(bytes32 flight) external payable;
    function test1() external;
    function test2() returns (uint256);
    function test3() public view returns (bool);
    function registerAirline(address airlineAddress) external;
    function registerInitialAirline() external;
    function returnInitialAirline() external returns(address);
    function returnAirlinesRegistered() external returns(uint);
    function fundAirline() external payable;
}