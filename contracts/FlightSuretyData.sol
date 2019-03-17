pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

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
        uint8 registrationNumb;
        address airline;
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


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor(address appAddress) public 
    {
        contractOwner = msg.sender;
        flightsRegistered = 100;
        //contractOwner = appAddress;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier flightExists(bytes32 flight)
    {
        require(flights[flight].updatedTimestamp != 0, "Flight does not exist");
        _;
    }

    modifier requireEtherMoreThanZero()
    {
        require(msg.value > 0 ether, "Ether required must be greater than zero.");
        _;
    }

    modifier requireEtherNoMoreThanOneEther()
    {
        require(msg.value <= 1 ether, "Ether required must be less or equal to 1.");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() public view returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool mode) external requireContractOwner 
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline() external pure
    {
    }

    
    function isAirline(address airline) public view returns(bool) 
    {
        // airlines[airline].registrationNumb = 4;
        // return false;
    }

    function registerFlight(bytes32 flight, uint timeStamp,uint8 statusCode,address airlineAddress) external
    {
        Flight memory newFlight = Flight(true,statusCode,timeStamp,airlineAddress);
        flights[flight] = newFlight;
        flightsRegistered++;
    }


    function isFlightRegistered(bytes32 flight) external returns (bool)
    {
        if (flights[flight].updatedTimestamp == 0) {
            return false;
        }   
        return true;
    }

    function test2() returns (uint256)
    {
        flightsRegistered = flightsRegistered.add(50);
        return flightsRegistered;
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy(bytes32 flight)
                            external
                            payable

                            flightExists(flight)
                            //requireEtherMoreThanZero
                            requireEtherNoMoreThanOneEther
    {
        address buyerAddress = msg.sender;
        PurchasedInsurance memory newInsurance = PurchasedInsurance(msg.value,buyerAddress);
        insurance[flight] = newInsurance;
    }

    function viewInsurancePurchasedForFlight(bytes32 flight) view returns(uint256)
    {
        uint256 amount = insurance[flight].purchaseAmount;
        return amount;
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(bytes32 flight) external returns(uint256)                                  
    {
        address creditAddress = msg.sender;
        uint256 amount0 = insurance[flight].purchaseAmount.div(2);
        uint256 amount1 = insurance[flight].purchaseAmount;
        uint256 returnAmount = amount0.add(amount1);
        account[creditAddress].creditAmount = amount1.add(amount0).add(account[creditAddress].creditAmount);
        return account[creditAddress].creditAmount;
    }


    function viewCreditedAccount() view returns(uint256)
    {
        address creditAddress = msg.sender;
        uint256 amount = account[creditAddress].creditAmount;
        return amount;
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay()external payable
    {
        require(account[msg.sender].creditAmount > 0);
        uint256 prev = account[msg.sender].creditAmount;
        account[msg.sender].creditAmount = 0;
        msg.sender.transfer(prev);
    }
    

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund( ) public payable
    {

    }

    function getFlightKey(address airline,string memory flight,uint256 timestamp) pure internal returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable 
    {
        fund();
    }
}

